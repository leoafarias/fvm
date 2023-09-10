import 'package:fvm/src/utils/helpers.dart';
import 'package:io/ansi.dart';
import 'package:io/io.dart';

import '../services/releases_service/releases_client.dart';
import '../utils/logger.dart';
import 'base_command.dart';

/// List installed SDK Versions
class ReleasesCommand extends BaseCommand {
  @override
  final name = 'releases';

  @override
  final description = 'View all Flutter SDK releases available for install.';

  /// Constructor
  ReleasesCommand();

  @override
  Future<int> run() async {
    final releases = await FlutterReleasesClient.get();

    final versions = releases.releases.reversed;

    for (var release in versions) {
      final version = yellow.wrap(release.version.padRight(17));

      final pipe = '|';
      final date = friendlyDate(release.releaseDate);

      if (release.activeChannel) {
        final channel = release.channel.toString().split('.').last;
        logger.info('--------------------------------------');
        logger.info('$date $pipe $version $channel');
        logger.info('--------------------------------------');
      } else {
        logger.info('$date $pipe $version');
      }
    }

    return ExitCode.success.code;
  }
}
