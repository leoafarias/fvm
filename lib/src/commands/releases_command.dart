import 'package:args/command_runner.dart';
import 'package:console/console.dart';
import 'package:date_format/date_format.dart';
import 'package:fvm/src/utils/logger.dart';
import 'package:io/ansi.dart';

import 'package:fvm/src/services/releases_service/releases_client.dart';
import 'package:io/io.dart';

/// List installed SDK Versions
class ReleasesCommand extends Command<int> {
  // The [name] and [description] properties must be defined by every
  // subclass.
  @override
  final name = 'releases';

  @override
  final description = 'View Flutter SDK releases.';

  /// Constructor
  ReleasesCommand();

  @override
  Future<int> run() async {
    final releases = await fetchFlutterReleases();

    final versions = releases.releases.reversed;

    versions.forEach((release) {
      final version = yellow.wrap(release.version.padRight(17));
      final pipe = Icon.PIPE_VERTICAL;
      final friendlyDate =
          formatDate(release.releaseDate, [M, ' ', d, ' ', yy]).padRight(10);

      if (release.activeChannel) {
        final channel = release.channel.toString().split('.').last;
        FvmLogger.info('--------------------------------------');
        FvmLogger.info('$friendlyDate $pipe $version $channel');
        FvmLogger.info('--------------------------------------');
      } else {
        FvmLogger.info('$friendlyDate $pipe $version');
      }
    });
    return ExitCode.success.code;
  }
}
