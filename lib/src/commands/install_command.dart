import 'package:args/command_runner.dart';
import 'package:io/io.dart';

import '../../exceptions.dart';
import '../../fvm.dart';
import '../services/flutter_app_service.dart';
import '../services/flutter_tools.dart';
import '../workflows/ensure_cache.workflow.dart';

/// Installs Flutter SDK
class InstallCommand extends Command<int> {
  @override
  final name = 'install';

  @override
  final description = 'Installs Flutter SDK Version';

  @override
  String get invocation =>
      'fvm install <channel/version>, if no <version> is provided will install version configured in project.';

  /// Constructor
  InstallCommand() {
    argParser.addFlag(
      'skip-setup',
      help: 'Skips Flutter setup after install',
      abbr: 's',
      negatable: false,
    );
  }

  @override
  Future<int> run() async {
    CacheVersion cacheVersion;
    final skipSetup = argResults['skip-setup'] == true;
    String version;

    // If no version was passed as argument check project config.
    if (argResults.rest.isEmpty) {
      version = await FlutterAppService.findVersion();

      // If no config found is version throw error
      if (version == null) {
        throw const FvmUsageException(
            '''Please provide a channel or a version, or run this command in a Flutter project that has FVM configured.''');
      }
    }
    version ??= argResults.rest[0];

    final validVersion = await FlutterTools.inferValidVersion(version);
    cacheVersion =
        await ensureCacheWorkflow(validVersion, skipConfirmation: true);

    if (!skipSetup) {
      await FlutterTools.setupSdk(cacheVersion);
    }

    return ExitCode.success.code;
  }
}
