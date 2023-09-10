import 'package:args/command_runner.dart';
import 'package:dart_console/dart_console.dart';
import 'package:fvm/constants.dart';
import 'package:fvm/src/utils/console_utils.dart';
import 'package:fvm/src/utils/helpers.dart';
import 'package:fvm/src/utils/logger.dart';
import 'package:mason_logger/mason_logger.dart';

import '../services/releases_service/releases_client.dart';
import 'base_command.dart';

/// List installed SDK Versions
class ReleasesCommand extends BaseCommand {
  @override
  final name = 'releases';

  @override
  final description = 'View all Flutter SDK releases available for install.';

  /// Constructor
  // Add option to pass channel name
  ReleasesCommand() {
    argParser.addOption(
      'channel',
      help: 'Filter by channel name',
      abbr: 'c',
    );
  }

  @override
  Future<int> run() async {
    // Get channel name
    final channelName = stringArg('channel');

    if (channelName != null) {
      logger.detail('Filtering by channel: $channelName');
      if (!kFlutterChannels.contains(channelName)) {
        throw UsageException('Invalid Channel name: $channelName', usage);
      }
    }

    final releases = await FlutterReleasesClient.get();

    final versions = releases.releases.reversed;

    final table = createTable()
      ..insertColumn(header: 'Version', alignment: TextAlignment.left)
      ..insertColumn(header: 'Release Date', alignment: TextAlignment.left)
      ..insertColumn(header: 'Channel', alignment: TextAlignment.left);

    for (var release in versions) {
      var channelLabel = release.channel.toString().split('.').last;
      if (release.activeChannel) {
        // Add checkmark icon
        // as ascii code
// Add backgroundColor
        final checkmark = String.fromCharCode(0x2713);

        channelLabel = '$channelLabel ${green.wrap(checkmark)}';
      }

      if (channelName != null && release.channel.name != channelName) {
        continue;
      }
      table.insertRow([
        release.version,
        friendlyDate(release.releaseDate),
        channelLabel,
      ]);
    }

    logger.info(table.toString());

    logger.info('Channel:');

    final channelsTable = createTable()
      ..insertColumn(header: 'Channel', alignment: TextAlignment.left)
      ..insertColumn(header: 'Version', alignment: TextAlignment.left)
      ..insertColumn(header: 'Release Date', alignment: TextAlignment.left);

    for (var release in releases.channels.toList) {
      if (channelName != null && release.channel.name != channelName) {
        continue;
      }
      channelsTable.insertRow([
        release.channel.name,
        release.version,
        friendlyDate(release.releaseDate)
      ]);
    }

    logger.info(channelsTable.toString());

    return ExitCode.success.code;
  }
}
