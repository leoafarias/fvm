import 'package:dart_console/dart_console.dart';
import 'package:mason_logger/mason_logger.dart';

import '../services/logger_service.dart';
import '../services/releases_service/models/version_model.dart';
import '../utils/get_directory_size.dart';
import '../utils/helpers.dart';
import 'base_command.dart';

/// List installed SDK Versions
class ListCommand extends BaseCommand {
  @override
  final name = 'list';

  @override
  final description = 'Lists installed Flutter SDK Versions';

  /// Constructor
  ListCommand(super.controller);

  @override
  Future<int> run() async {
    final cacheVersions = await controller.cacheService.getAllVersions();

    final directorySize = await getFullDirectorySize(cacheVersions);

    // Print where versions are stored
    logger
      ..info(
        'Cache directory:  ${cyan.wrap(controller.context.versionsCachePath)}',
      )
      ..info('Directory Size: ${formatBytes(directorySize)}')
      ..spacer;

    if (cacheVersions.any((e) => e.isNotSetup)) {
      logger
        ..warn(
          'Some versions might still require finishing setup - SDKs have been cloned, but they have not downloaded their dependencies.',
        )
        ..info(
          'This will complete the first time you run any command with the SDK.',
        )
        ..spacer;
    }
    if (cacheVersions.isEmpty) {
      logger
        ..info('No SDKs have been installed yet. Flutter. SDKs')
        ..info('installed outside of fvm will not be displayed.');

      return ExitCode.success.code;
    }

    final releases = await controller.flutterReleasesServices.getReleases();
    final globalVersion = controller.globalVersionService.getGlobal();
    final localVersion = controller.projectService.findVersion();

    final table = Table()
      ..insertColumn(header: 'Version', alignment: TextAlignment.left)
      ..insertColumn(header: 'Channel', alignment: TextAlignment.left)
      ..insertColumn(header: 'Flutter Version', alignment: TextAlignment.left)
      ..insertColumn(header: 'Dart Version', alignment: TextAlignment.left)
      ..insertColumn(header: 'Release Date', alignment: TextAlignment.left)
      ..insertColumn(header: 'Global', alignment: TextAlignment.left)
      ..insertColumn(header: 'Local', alignment: TextAlignment.left);

    for (var version in cacheVersions) {
      var printVersion = version.name;
      FlutterSdkRelease? latestRelease;

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
        if (version.isNotSetup) {
          return flutterSdkVersion = '${yellow.wrap('Need setup*')}';
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
            localVersion == printVersion && localVersion != null
                ? green.wrap(dot)!
                : '',
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
