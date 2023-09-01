import 'package:fvm/src/utils/logger.dart';
import 'package:mason_logger/mason_logger.dart';

int lastPercentage = 0;

void updateProgress(String line) {
  final regexes = {
    'Enumerating objects:': RegExp(r'Enumerating objects: +(\d+)%'),
    'Counting objects:': RegExp(r'Counting objects: +(\d+)%'),
    'Compressing objects:': RegExp(r'Compressing objects: +(\d+)%'),
    'Receiving objects:': RegExp(r'Receiving objects: +(\d+)%'),
    'Resolving deltas:': RegExp(r'Resolving deltas: +(\d+)%'),
  };

  final maxLabelLength =
      regexes.keys.map((e) => e.length).reduce((a, b) => a > b ? a : b);

  bool matched = false;
  for (final entry in regexes.entries) {
    final label = entry.key.padRight(maxLabelLength);
    final regex = entry.value;
    final match = regex.firstMatch(line);
    if (match != null) {
      final percentage = int.parse(match.group(1)!);
      if (percentage != lastPercentage) {
        printProgressBar(label, percentage);
        lastPercentage = percentage;
      }
      matched = true;
      break;
    }
  }
  if (!matched) {
    logger.info(line);
  }
}

void printProgressBar(String label, int percentage) {
  final progressBarWidth = 50;
  final progressInBlocks = (percentage / 100 * progressBarWidth).round();
  final progressBlocks = '${green.wrap('█')}' * progressInBlocks;
  final remainingBlocks = '.' * (progressBarWidth - progressInBlocks);

  final output = '\r $label [$progressBlocks$remainingBlocks] $percentage%';

  logger.write(output);

  // Move cursor to the next line if progress is complete
  if (percentage == 100) {
    logger.write('\n');
  }
}
