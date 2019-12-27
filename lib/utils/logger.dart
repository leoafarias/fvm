import 'package:cli_util/cli_logging.dart';
import 'package:fvm/constants.dart';

/// Log
Logger logger = Logger.standard();

/// Finishes progress
void finishProgress(Progress progress) {
  progress.finish(showTiming: true);
}

/// Warning if you are not using an official source.
void checkFlutterRemote(String url) {
  if (url != kFlutterRepo) {
    logger.stdout(
        'The flutter remote is $url. This is not an official source, you need to confirm the security yourself.');
  }
}
