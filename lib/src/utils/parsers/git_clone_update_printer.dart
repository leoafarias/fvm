import 'dart:convert';
import 'dart:io';

import 'package:mason_logger/mason_logger.dart';

import '../context.dart';
import '../extensions.dart';

final regexes = {
  'Enumerating objects:': RegExp(r'Enumerating objects: +(\d+)%'),
  'Counting objects:': RegExp(r'Counting objects: +(\d+)%'),
  'Compressing objects:': RegExp(r'Compressing objects: +(\d+)%'),
  'Receiving objects:': RegExp(r'Receiving objects: +(\d+)%'),
  'Resolving deltas:': RegExp(r'Resolving deltas: +(\d+)%'),
};

int lastPercentage = 0;
String lastMatchedEntry = '';

final maxLabelLength =
    regexes.keys.map((e) => e.length).reduce((a, b) => a > b ? a : b);

var _hasFailedPrint = false;

void updateProgress(String line) {
  if (_hasFailedPrint) {
    ctx.loggerService.info('\n');

    return;
  }
  try {
    final matchedEntry = regexes.entries.firstWhereOrNull(
      (entry) => line.contains(entry.key),
    );

    if (matchedEntry != null) {
      final label = matchedEntry.key.padRight(maxLabelLength);
      final match = matchedEntry.value.firstMatch(line);
      final percentValue = match?.group(1);
      int? percentage = int.tryParse(percentValue ?? '');

      if (percentage != lastPercentage) {
        if (percentage == null) return;

        if (lastMatchedEntry.isNotEmpty && lastMatchedEntry != label) {
          printProgressBar(lastMatchedEntry, 100);
          ctx.loggerService.write('\n');
        }

        printProgressBar(label, percentage);

        lastPercentage = percentage;
        lastMatchedEntry = label;
      }
    }
  } catch (e) {
    ctx.loggerService.detail('Failed to update progress bar $e');
    _hasFailedPrint = true;
  }
}

void printProgressBar(String label, int percentage) {
  final progressBarWidth = 50;
  final progressInBlocks = (percentage / 100 * progressBarWidth).round();
  final progressBlocks = '${green.wrap('█')}' * progressInBlocks;
  final remainingBlocks = '.' * (progressBarWidth - progressInBlocks);

  final output = '\r $label [$progressBlocks$remainingBlocks] $percentage%';

  ctx.loggerService.write(output);
}

// Create a custom Process.start, that prints using the progress bar
Future<void> runGitCloneUpdate(List<String> args) async {
  final process = await Process.start('git', args, runInShell: true);

  final processLogs = <String>[];

  try {
    // ignore: avoid-unassigned-stream-subscriptions
    process.stderr.transform(utf8.decoder).listen((line) {
      updateProgress(line);
      processLogs.add(line);
    });

    // ignore: avoid-unassigned-stream-subscriptions
    process.stdout.transform(utf8.decoder).listen((line) {
      ctx.loggerService.info(line);
    });
  } catch (e) {
    ctx.loggerService.detail('Formatting error due to invalid return $e');
    ctx.loggerService.info('Updating....');
  }

  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    ctx.loggerService.err(processLogs.join('\n'));
    throw Exception('Git clone failed');
  }
  ctx.loggerService
    ..spacer
    ..success('Clone complete');
}
