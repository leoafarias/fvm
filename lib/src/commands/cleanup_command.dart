import 'package:io/io.dart';

import '../models/cleanup_model.dart';
import '../models/flutter_version_model.dart';
import '../services/cache_service.dart';
import '../services/cleanup_service.dart';
import 'base_command.dart';

/// Shows and optionally applies safe cache cleanup recommendations.
class CleanupCommand extends BaseFvmCommand {
  @override
  final name = 'cleanup';

  @override
  final description =
      'Shows cache cleanup and same-line patch upgrade recommendations';

  CleanupCommand(super.context) {
    argParser
      ..addFlag(
        'remove-unused',
        help: 'Removes unused SDKs, except cached patches recommended as '
            'upgrade targets',
        negatable: false,
      )
      ..addFlag(
        'yes',
        abbr: 'y',
        help: 'Skips confirmation when removing unused SDKs',
        negatable: false,
      );
  }

  void _printPlan({
    required List<PatchUpgrade> upgrades,
    required List<String> unused,
  }) {
    if (upgrades.isEmpty && unused.isEmpty) {
      logger.info('No patch upgrades or unused SDKs.');

      return;
    }

    if (upgrades.isNotEmpty) {
      logger.info('Cached patch upgrades:');
      for (final upgrade in upgrades) {
        logger.info('  ${upgrade.fromVersion} → ${upgrade.toVersion}');
        for (final action in upgrade.actions) {
          logger.info('    Run: fvm ${action.arguments.join(' ')}');
          if (action.workingDirectory != null) {
            logger.info('    in ${action.workingDirectory}');
          }
        }
      }
      logger.info(
        'Newer cached patches recommended as upgrade targets are not '
        'offered for removal.',
      );
    }

    if (unused.isNotEmpty) {
      if (upgrades.isNotEmpty) logger.info();
      logger.info('Unused SDKs:');
      for (final version in unused) {
        logger.info('  $version');
      }
      logger.info(
        'No known project pins these SDKs and they are not selected globally.',
      );
      if (!boolArg('remove-unused')) {
        logger.info(
          'Run "fvm cleanup --remove-unused" to review and remove them.',
        );
      }
    }
  }

  Future<void> _removeUnusedSdks(List<String> versions) async {
    if (versions.isEmpty) {
      logger.info('No unused SDKs to remove.');

      return;
    }

    final confirmed = boolArg('yes') ||
        logger.confirm(
          'Remove ${versions.length} unused SDK${versions.length == 1 ? '' : 's'}: ${versions.join(', ')}?',
          defaultValue: false,
        );
    if (!confirmed) {
      logger.info('No SDKs were removed.');

      return;
    }

    for (final version in versions) {
      await get<CacheService>().remove(FlutterVersion.parse(version));
      logger.success('$version removed.');
    }
  }

  @override
  Future<int> run() async {
    final plan = await get<CleanupService>().plan();

    _printPlan(upgrades: plan.upgrades, unused: plan.unused);

    if (boolArg('remove-unused')) {
      await _removeUnusedSdks(plan.unused);
    }

    return ExitCode.success.code;
  }
}
