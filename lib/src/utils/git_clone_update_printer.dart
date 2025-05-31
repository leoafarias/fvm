import 'package:io/ansi.dart';

import '../services/logger_service.dart';
import 'extensions.dart';

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

void printProgressBar(String line, Logger logger) {
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
          _printProgressBar(lastMatchedEntry, 100, logger);
          logger.write('\n');
        }

        _printProgressBar(label, percentage, logger);

        lastPercentage = percentage;
        lastMatchedEntry = label;
      }
    }
  } catch (e) {
    logger.debug('Failed to update progress bar $e');
    _hasFailedPrint = true;
  }
}

void _printProgressBar(String label, int percentage, Logger logger) {
  final progressBarWidth = 50;
  final progressInBlocks = (percentage / 100 * progressBarWidth).round();
  final progressBlocks = '${green.wrap('█')}' * progressInBlocks;
  final remainingBlocks = '.' * (progressBarWidth - progressInBlocks);

  final output = '\r $label [$progressBlocks$remainingBlocks] $percentage%';

  logger.write(output);
}
