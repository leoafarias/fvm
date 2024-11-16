import 'package:dart_console/dart_console.dart';
import 'package:mason_logger/mason_logger.dart';

import '../models/flutter_version_model.dart';
import '../services/cache_service.dart';
import '../services/global_version_service.dart';
import '../services/logger_service.dart';
import '../services/project_service.dart';
import '../services/releases_service/models/version_model.dart';
import '../services/releases_service/releases_client.dart';
import '../utils/context.dart';
import '../utils/get_directory_size.dart';
import '../utils/helpers.dart';
import 'base_command.dart';

// ERRORS
enum ListCommandException implements Exception {
  noSDKsInstalled;
}

// SERVICE
class ListCommandService {
  static Future<ListCommandData> run() async {
    final cacheVersions = await CacheService.fromContext.getAllVersions();

    final directorySize = await getFullDirectorySize(cacheVersions);

    if (cacheVersions.isEmpty) {
      throw ListCommandException.noSDKsInstalled;
    }

    final releases = await FlutterReleasesClient.getReleases();
    final globalVersion = GlobalVersionService.fromContext.getGlobal();
    final localVersion = ProjectService.fromContext.findVersion();

    final versions = <VersionInfo>[];

    for (var version in cacheVersions) {
      FlutterSdkRelease? latestRelease;

      if (version.isChannel && !version.isMaster) {
        latestRelease = releases.getLatestChannelRelease(version.name);
      }

      final release =
          releases.getReleaseFromVersion(version.flutterSdkVersion ?? '');

      final versionInfo = VersionInfo(
        name: version.name,
        type: version.type,
        flutterSdkVersion: version.flutterSdkVersion,
        dartSdkVersion: version.dartSdkVersion,
        release: release,
        isGlobal: globalVersion == version,
        isLocal: localVersion == version.name && localVersion != null,
        needsSetup: version.isNotSetup,
        latestRelease: latestRelease,
      );

      versions.add(versionInfo);
    }

    return ListCommandData(
      versions: versions,
      directorySize: directorySize,
      versionsCachePath: ctx.versionsCachePath,
    );
  }
}

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
    final ui = ListCommandUI(logger: logger);

    try {
      final data = await ListCommandService.run();
      ui.render(data);
    } on ListCommandException catch (e) {
      switch (e) {
        case ListCommandException.noSDKsInstalled:
          ui.renderNoSDKsInstalled();
      }
    }

    return ExitCode.success.code;
  }

  @override
  List<String> get aliases => ['ls'];
}

// DATA
class ListCommandData {
  final List<VersionInfo> versions;
  final int directorySize;
  final String versionsCachePath;

  const ListCommandData({
    required this.versions,
    required this.directorySize,
    required this.versionsCachePath,
  });
}

class VersionInfo {
  final String name;
  final VersionType type;
  final String? flutterSdkVersion;
  final String? dartSdkVersion;
  final FlutterSdkRelease? release;
  final bool isGlobal;
  final bool isLocal;
  final bool needsSetup;
  final FlutterSdkRelease? latestRelease;

  const VersionInfo({
    required this.name,
    required this.type,
    this.flutterSdkVersion,
    this.dartSdkVersion,
    this.release,
    required this.isGlobal,
    required this.isLocal,
    required this.needsSetup,
    this.latestRelease,
  });
}

// UI
class ListCommandUI {
  final LoggerService logger;

  const ListCommandUI({required this.logger});

  void render(ListCommandData data) {
    logger
      ..info('Cache directory:  ${cyan.wrap(data.versionsCachePath)}')
      ..info('Directory Size: ${formatBytes(data.directorySize)}')
      ..spacer;

    if (data.versions.any((e) => e.needsSetup)) {
      logger
        ..warn(
          'Some versions might still require finishing setup - SDKs have been cloned, but they have not downloaded their dependencies.',
        )
        ..info(
          'This will complete the first time you run any command with the SDK.',
        )
        ..spacer;
    }

    final table = Table()
      ..insertColumn(header: 'Version', alignment: TextAlignment.left)
      ..insertColumn(header: 'Channel', alignment: TextAlignment.left)
      ..insertColumn(header: 'Flutter Version', alignment: TextAlignment.left)
      ..insertColumn(header: 'Dart Version', alignment: TextAlignment.left)
      ..insertColumn(header: 'Release Date', alignment: TextAlignment.left)
      ..insertColumn(header: 'Global', alignment: TextAlignment.left)
      ..insertColumn(header: 'Local', alignment: TextAlignment.left);

    for (var version in data.versions) {
      String releaseDate = '';
      String channel = '';

      final release = version.release;

      print(release);
      if (release != null) {
        releaseDate = friendlyDate(release.releaseDate);
        channel = release.channel.name;
      }

      String flutterSdkVersion = version.flutterSdkVersion ?? '';

      String getVersionOutput() {
        if (version.needsSetup) {
          return flutterSdkVersion = '${yellow.wrap('Need setup*')}';
        }

        final latestRelease = version.latestRelease;

        if (latestRelease != null && version.type == VersionType.channel) {
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
            version.name,
            channel,
            getVersionOutput(),
            version.dartSdkVersion ?? '',
            releaseDate,
            version.isGlobal ? green.wrap(dot)! : '',
            version.isLocal ? green.wrap(dot)! : '',
          ],
        ])
        ..borderStyle = BorderStyle.square
        ..borderColor = ConsoleColor.white
        ..borderType = BorderType.grid
        ..headerStyle = FontStyle.bold;
    }

    logger.info(table.toString());
  }

  void renderNoSDKsInstalled() {
    logger
      ..info('No SDKs have been installed yet. Flutter. SDKs')
      ..info('installed outside of fvm will not be displayed.');
  }
}
