import 'package:dart_console/dart_console.dart';
import 'package:fvm/src/services/releases_service/releases_client.dart';
import 'package:fvm/src/utils/helpers.dart';
import 'package:mason_logger/mason_logger.dart';

import '../services/cache_service.dart';
import '../utils/context.dart';
import '../utils/logger.dart';
import 'base_command.dart';

/// List installed SDK Versions
class ListCommand extends BaseCommand {
  @override
  final name = 'list';

  @override
  final description = 'Lists installed Flutter SDK Versions';

  @override
  List<String> get aliases => ['ls'];

  /// Constructor
  ListCommand();

  @override
  Future<int> run() async {
    final cacheVersions = await CacheService.instance.getAllVersions();

    if (cacheVersions.isEmpty) {
      logger
        ..info('No SDKs have been installed yet. Flutter. SDKs')
        ..info('installed outside of fvm will not be displayed.');
      return ExitCode.success.code;
    }

    // Print where versions are stored
    logger
      ..info('Cache directory:  ${cyan.wrap(ctx.fvmVersionsDir)}')
      ..spacer;

    final releases = await FlutterReleasesClient.get();
    final globalVersion = CacheService.instance.getGlobal();
    final table = Table()
      ..insertColumn(header: 'SDK', alignment: TextAlignment.left)
      ..insertColumn(header: 'Channel', alignment: TextAlignment.left)
      ..insertColumn(header: 'Flutter Version', alignment: TextAlignment.left)
      ..insertColumn(header: 'Dart  Version', alignment: TextAlignment.left)
      ..insertColumn(header: 'Release Date', alignment: TextAlignment.left)
      ..insertColumn(header: 'Is Global', alignment: TextAlignment.left);

    for (var version in cacheVersions) {
      var printVersion = version.name;

      final release = releases.getReleaseFromVersion(version.name);

      String releaseDate = '';
      String channel = '';

      if (release != null) {
        releaseDate = friendlyDate(release.releaseDate);
        channel = release.channel.name;
      }

      if (version.notSetup) {
        printVersion = '${version.name} \n${yellow.wrap('Need setup')}';
      }

      table
        ..insertRows([
          [
            printVersion,
            channel,
            version.flutterSdkVersion ?? '',
            version.dartSdkVersion ?? '',
            releaseDate,
            globalVersion == version ? green.wrap('Yes')! : red.wrap('No')!,
          ]
        ])
        ..borderStyle = BorderStyle.square
        ..borderColor = ConsoleColor.blue
        ..borderType = BorderType.grid
        ..headerStyle = FontStyle.bold;
    }
    logger.info(table.toString());

    return ExitCode.success.code;
  }
}
