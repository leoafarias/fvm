import 'package:fvm/src/commands/tui_command.dart';
import 'package:fvm/src/models/cache_flutter_version_model.dart';
import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:io/io.dart';
import 'package:muse/muse.dart';
import 'package:test/test.dart';

import '../../testing_utils.dart';

void main() {
  group('TuiCommand', () {
    test('exits with usage when input is skipped', () async {
      final context = TestFactory.fastContext(skipInput: true);
      final runner = TestFactory.fastCommandRunner(context: context);

      final exitCode = await runner.run(['fvm', 'tui', '--sample']);

      expect(exitCode, ExitCode.usage.code);
    });
  });

  group('FvmTuiVersionChoice', () {
    test('builds status and row labels for display', () {
      const choice = FvmTuiVersionChoice(
        name: 'stable',
        kind: 'channel',
        channel: 'stable channel',
        flutterVersion: '3.32.5',
        dartVersion: '3.8.1',
        releaseDate: '2026-06-18',
        cachePath: '/Users/test/.fvm/versions/stable',
        alias: 'client-a',
        isProject: true,
        needsSetup: true,
      );

      expect(
        choice.statusTags,
        ['project', 'needs setup', 'alias client-a'],
      );
      expect(choice.statusSummary, 'project | needs setup | alias client-a');
      expect(choice.healthLabel, 'Needs setup');
      expect(choice.rowLabel, 'stable');
      expect(choice.rowDescription, contains('project'));
      expect(choice.rowDescription, contains('Flutter 3.32.5'));
    });

    test('keeps long labels within terminal cell budgets', () {
      const choice = FvmTuiVersionChoice(
        name: 'custom-fork-with-a-long-name/3.32.5@beta',
        kind: 'forked release',
        channel: 'beta',
        flutterVersion: '3.32.5',
        dartVersion: '3.8.1',
        releaseDate: '2026-06-18',
        cachePath:
            '/very/long/cache/path/custom-fork-with-a-long-name/3.32.5@beta',
      );

      expect(terminalStringWidth(choice.rowLabel), lessThanOrEqualTo(30));
      expect(terminalStringWidth(choice.rowDescription), lessThanOrEqualTo(48));
      expect(terminalStringWidth(choice.titleLabel), lessThanOrEqualTo(28));
      expect(
        terminalStringWidth(choice.statusSummaryLabel),
        lessThanOrEqualTo(28),
      );
      expect(terminalStringWidth(choice.cachePathLabel), lessThanOrEqualTo(20));
    });

    test('derives display metadata from cached versions', () {
      const cacheVersion = CacheFlutterVersion(
        'stable',
        type: VersionType.channel,
        directory: '/tmp/fvm/stable',
        flutterSdkVersion: '3.32.5',
        dartSdkVersion: '3.8.1',
        isSetup: false,
      );

      final choice = FvmTuiVersionChoice.fromCache(
        cacheVersion,
        isGlobal: true,
        isProject: false,
      );

      expect(choice.kind, 'channel');
      expect(choice.needsSetup, isTrue);
      expect(choice.statusTags, ['global', 'needs setup']);
      expect(choice.healthLabel, 'Needs setup');
      expect(choice.rowDescription, contains('global'));
    });
  });
}
