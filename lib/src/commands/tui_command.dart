import 'dart:async';

import 'package:io/io.dart';
import 'package:muse/muse.dart';

import '../models/cache_flutter_version_model.dart';
import '../services/cache_service.dart';
import '../services/project_service.dart';
import '../services/releases_service/models/flutter_releases_model.dart';
import '../services/releases_service/releases_client.dart';
import '../utils/helpers.dart';
import 'base_command.dart';

part 'tui/empty_cache_message.dart';
part 'tui/field.dart';
part 'tui/footer.dart';
part 'tui/header.dart';
part 'tui/tui_app.dart';
part 'tui/tui_models.dart';
part 'tui/tui_theme.dart';
part 'tui/version_details.dart';
part 'tui/version_select.dart';

/// Preview cached SDK versions in an experimental Muse terminal UI.
class TuiCommand extends BaseFvmCommand {
  @override
  final name = 'tui';

  @override
  final description = 'Previews cached Flutter SDK versions in a Muse TUI';

  TuiCommand(super.context) {
    argParser.addFlag(
      'sample',
      help: 'Shows sample SDK rows instead of reading the local FVM cache',
      negatable: false,
    );
  }

  Future<List<FvmTuiVersionChoice>> _loadCacheChoices() async {
    final cacheService = get<CacheService>();
    final versions = await cacheService.getAllVersions();
    final globalVersion = cacheService.getGlobal();
    final localVersion = get<ProjectService>().findVersion();

    FlutterReleasesResponse? releases;
    try {
      releases = await get<FlutterReleaseClient>().fetchReleases();
    } on Object catch (error) {
      logger.debug('Could not fetch release metadata for TUI: $error');
    }

    return [
      for (final version in versions)
        FvmTuiVersionChoice.fromCache(
          version,
          releases: releases,
          isGlobal: globalVersion?.nameWithAlias == version.nameWithAlias,
          isProject: localVersion == version.nameWithAlias,
        ),
    ];
  }

  List<FvmTuiVersionChoice> _sampleChoices() => const [
        FvmTuiVersionChoice(
          name: 'stable',
          kind: 'channel',
          channel: 'stable channel',
          flutterVersion: '3.32.5',
          dartVersion: '3.8.1',
          releaseDate: '2026-06-18',
          cachePath: '~/.fvm/versions/stable',
          isProject: true,
        ),
        FvmTuiVersionChoice(
          name: '3.32.4',
          kind: 'release',
          channel: 'stable release',
          flutterVersion: '3.32.4',
          dartVersion: '3.8.1',
          releaseDate: '2026-06-10',
          cachePath: '~/.fvm/versions/3.32.4',
          alias: 'client-a',
        ),
        FvmTuiVersionChoice(
          name: '3.29.3',
          kind: 'release',
          channel: 'stable release',
          flutterVersion: '3.29.3',
          dartVersion: '3.7.2',
          releaseDate: '2026-04-16',
          cachePath: '~/.fvm/versions/3.29.3',
          isGlobal: true,
        ),
        FvmTuiVersionChoice(
          name: 'beta',
          kind: 'channel',
          channel: 'beta channel',
          flutterVersion: '3.33.0-0.2.pre',
          dartVersion: '3.9.0',
          releaseDate: '2026-06-20',
          cachePath: '~/.fvm/versions/beta',
        ),
        FvmTuiVersionChoice(
          name: 'custom-fork/3.24.0@beta',
          kind: 'forked release',
          channel: 'forked beta',
          flutterVersion: '3.24.0',
          dartVersion: '3.5.0',
          releaseDate: '2025-09-12',
          cachePath: '~/.fvm/versions/custom-fork/3.24.0@beta',
        ),
      ];

  @override
  Future<int> run() async {
    if (context.skipInput) {
      logger.err('The tui command requires an interactive terminal.');

      return ExitCode.usage.code;
    }

    final choices =
        boolArg('sample') ? _sampleChoices() : await _loadCacheChoices();

    TuiBinding? binding;
    final completion = Completer<_TuiCompletion>();

    void complete(_TuiCompletion result) {
      if (completion.isCompleted) {
        return;
      }

      binding?.dispose();
      completion.complete(result);
    }

    binding = runTuiApp(_FvmTuiApp(choices: choices, onComplete: complete));
    try {
      binding.enableMouse();
    } on Object catch (error) {
      logger.debug('Could not enable mouse support for TUI: $error');
    }

    final result = await completion.future;
    // Let Muse finish restoring terminal modes before writing normal CLI output.
    await Future<void>.delayed(Duration.zero);

    final selected = result.selected;
    if (selected == null) {
      logger.info('TUI cancelled.');

      return 130;
    }

    logger.info('Selected Flutter SDK: ${selected.name}');

    return ExitCode.success.code;
  }
}
