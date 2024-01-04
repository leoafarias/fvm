import 'dart:convert';
import 'dart:io';

import 'package:fvm/src/services/logger_service.dart';
import 'package:fvm/src/utils/extensions.dart';
import 'package:mason_logger/mason_logger.dart';

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

void updateProgress(String line) {
  final matchedEntry = regexes.entries.firstWhereOrNull(
    (entry) => line.contains(entry.key),
  );

  if (matchedEntry != null) {
    final label = matchedEntry.key.padRight(maxLabelLength);
    final match = matchedEntry.value.firstMatch(line);
    final percentVaue = match?.group(1);
    int? percentage = int.tryParse(percentVaue ?? '');

    if (percentage != lastPercentage) {
      if (percentage == null) return;

      if (lastMatchedEntry.isNotEmpty && lastMatchedEntry != label) {
        printProgressBar(lastMatchedEntry, 100);
        logger.write('\n');
      }

      printProgressBar(label, percentage);

      lastPercentage = percentage;
      lastMatchedEntry = label;
    }
  }
}

void printProgressBar(String label, int percentage) {
  final progressBarWidth = 50;
  final progressInBlocks = (percentage / 100 * progressBarWidth).round();
  final progressBlocks = '${green.wrap('█')}' * progressInBlocks;
  final remainingBlocks = '.' * (progressBarWidth - progressInBlocks);

  final output = '\r $label [$progressBlocks$remainingBlocks] $percentage%';

  logger.write(output);
}

// Create a custom Process.start, that prints using the progress bar
Future<void> runGitCloneUpdate(List<String> args) async {
  final process = await Process.start('git', args);

  process.stderr.transform(utf8.decoder).listen((line) {
    updateProgress(line);
  });

  process.stdout.transform(utf8.decoder).listen((line) {
    logger.info(line);
  });

  final exitCode = await process.exitCode;
  logger
    ..spacer
    ..success('Clone complete');
  if (exitCode != 0) {
    throw Exception('Git clone failed');
  }
}
