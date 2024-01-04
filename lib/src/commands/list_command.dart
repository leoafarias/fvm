import 'package:dart_console/dart_console.dart';
import 'package:fvm/src/services/global_version_service.dart';
import 'package:fvm/src/services/releases_service/models/release.model.dart';
import 'package:fvm/src/services/releases_service/releases_client.dart';
import 'package:fvm/src/utils/helpers.dart';
import 'package:mason_logger/mason_logger.dart';

import '../services/cache_service.dart';
import '../services/logger_service.dart';
import '../utils/context.dart';
import 'base_command.dart';

/// List installed SDK Versions
class ListCommand extends BaseCommand {
  @override
  final name = 'list';

  @override
  final description = 'Lists installed Flutter SDK Versions';

  /// Constructor
  ListCommand();

  @override
  Future<int> run() async {
    final cacheVersions = await CacheService.fromContext.getAllVersions();

    if (cacheVersions.isEmpty) {
      logger
        ..info('No SDKs have been installed yet. Flutter. SDKs')
        ..info('installed outside of fvm will not be displayed.');
      return ExitCode.success.code;
    }

    // Print where versions are stored
    logger
      ..info('Cache directory:  ${cyan.wrap(ctx.versionsCachePath)}')
      ..spacer;

    final releases = await FlutterReleases.get();
    final globalVersion = GlobalVersionService.fromContext.getGlobal();

    final table = Table()
      ..insertColumn(header: 'Version', alignment: TextAlignment.left)
      ..insertColumn(header: 'Channel', alignment: TextAlignment.left)
      ..insertColumn(header: 'Flutter Version', alignment: TextAlignment.left)
      ..insertColumn(header: 'Dart Version', alignment: TextAlignment.left)
      ..insertColumn(header: 'Release Date', alignment: TextAlignment.left)
      ..insertColumn(header: 'Global', alignment: TextAlignment.left);

    for (var version in cacheVersions) {
      var printVersion = version.name;
      Release? latestRelease;

      if (version.isChannel && !version.isMaster) {
        latestRelease = releases.getLatestChannelRelease(version.name);
      }

      final release =
          releases.getReleaseFromVersion(version.flutterSdkVersion ?? '');

      String releaseDate = '';
      String channel = '';

      if (release != null) {
        releaseDate = friendlyDate(release.releaseDate);
        channel = release.channel.name;
      }

      String flutterSdkVersion = version.flutterSdkVersion ?? '';

      String getVersionOutput() {
        if (version.notSetup) {
          return flutterSdkVersion = '${yellow.wrap('Need setup')}';
        }
        if (latestRelease != null && version.isChannel) {
          // If its not the latest version
          if (latestRelease.version != version.flutterSdkVersion) {
            return '$flutterSdkVersion $rightArrow ${(green.wrap(latestRelease.version))}';
          }
          return flutterSdkVersion;
        }
        return flutterSdkVersion;
      }

      table
        ..insertRows([
          [
            printVersion,
            channel,
            getVersionOutput(),
            version.dartSdkVersion ?? '',
            releaseDate,
            globalVersion == version ? green.wrap(dot)! : '',
          ],
        ])
        ..borderStyle = BorderStyle.square
        ..borderColor = ConsoleColor.white
        ..borderType = BorderType.grid
        ..headerStyle = FontStyle.bold;
    }
    logger.info(table.toString());

    return ExitCode.success.code;
  }

  @override
  List<String> get aliases => ['ls'];
}
