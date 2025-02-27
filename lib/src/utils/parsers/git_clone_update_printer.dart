import 'dart:convert';
import 'dart:io';

import 'package:io/ansi.dart';

import '../../services/logger_service.dart';
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

void updateProgress(String line, Logger logger) {
  if (_hasFailedPrint) {
    logger.info('\n');

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
          printProgressBar(lastMatchedEntry, 100, logger);
          logger.write('\n');
        }

        printProgressBar(label, percentage, logger);

        lastPercentage = percentage;
        lastMatchedEntry = label;
      }
    }
  } catch (e) {
    logger.detail('Failed to update progress bar $e');
    _hasFailedPrint = true;
  }
}

void printProgressBar(String label, int percentage, Logger logger) {
  final progressBarWidth = 50;
  final progressInBlocks = (percentage / 100 * progressBarWidth).round();
  final progressBlocks = '${green.wrap('█')}' * progressInBlocks;
  final remainingBlocks = '.' * (progressBarWidth - progressInBlocks);

  final output = '\r $label [$progressBlocks$remainingBlocks] $percentage%';

  logger.write(output);
}

// Create a custom Process.start, that prints using the progress bar
Future<void> runGitCloneUpdate(List<String> args, Logger logger) async {
  final process = await Process.start('git', args, runInShell: true);

  final processLogs = <String>[];

  try {
    // ignore: avoid-unassigned-stream-subscriptions
    process.stderr.transform(utf8.decoder).listen((line) {
      updateProgress(line, logger);
      processLogs.add(line);
    });

    // ignore: avoid-unassigned-stream-subscriptions
    process.stdout.transform(utf8.decoder).listen((line) {
      logger.info(line);
    });
  } catch (e) {
    logger.detail('Formatting error due to invalid return $e');
    logger.info('Updating....');
  }

  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    logger.err(processLogs.join('\n'));
    throw Exception('Git clone failed');
  }
  logger
    ..info('')
    ..success('Clone complete');
}
