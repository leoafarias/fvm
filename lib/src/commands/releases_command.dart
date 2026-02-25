import 'package:args/command_runner.dart';
import 'package:dart_console/dart_console.dart';
import 'package:mason_logger/mason_logger.dart';

import '../services/releases_service/models/version_model.dart';
import '../services/releases_service/releases_client.dart';
import '../utils/console_utils.dart';
import '../utils/helpers.dart';
import 'base_command.dart';

/// List installed SDK Versions
class ReleasesCommand extends BaseFvmCommand {
  @override
  final name = 'releases';

  @override
  final description =
      'Lists all Flutter SDK releases available for installation';

  // Add option to pass channel name
  ReleasesCommand(super.context) {
    argParser.addOption(
      'channel',
      abbr: 'c',
      help: 'Filter releases by channel (stable, beta, dev, all)',
      allowed: ['stable', 'beta', 'dev', 'all'],
      defaultsTo: 'stable',
    );
  }

  @override
  Future<int> run() async {
    // Get channel name
    final channelName = stringArg('channel');
    final allChannel = 'all';

    if (channelName != null) {
      if (!isFlutterChannel(channelName) && channelName != allChannel) {
        throw UsageException('Invalid Channel name: $channelName', usage);
      }
    }

    bool shouldFilterRelease(FlutterSdkRelease release) {
      if (channelName == allChannel) {
        return false;
      }

      return release.channel.name != channelName;
    }

    logger.debug('Filtering by channel: $channelName');

    final releases = await get<FlutterReleaseClient>().fetchReleases();

    final versions = releases.versions.reversed;

    final table = createTable()
      ..insertColumn(header: 'Version', alignment: TextAlignment.left)
      ..insertColumn(header: 'Dart SDK', alignment: TextAlignment.left)
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

      if (shouldFilterRelease(release)) {
        continue;
      }

      table.insertRow([
        release.version,
        release.dartSdkVersion ?? 'n/a',
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
      if (shouldFilterRelease(release)) {
        continue;
      }
      channelsTable.insertRow([
        release.channel.name,
        release.version,
        friendlyDate(release.releaseDate),
      ]);
    }

    logger.info(channelsTable.toString());

    return ExitCode.success.code;
  }
}
