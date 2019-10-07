import 'package:cli_util/cli_logging.dart';

/// Log
Logger logger = Logger.standard();

/// Finishes progress
void finishProgress(Progress progress) {
  progress.finish(showTiming: true);
}
