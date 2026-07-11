import 'package:fvm/fvm.dart';
import 'package:fvm/src/commands/list_command.dart';
import 'package:fvm/src/services/logger_service.dart';
import 'package:io/io.dart';
import 'package:test/test.dart';

import '../../testing_utils.dart';

void main() {
  group('ListCommand', () {
    test('shows the latest release for an outdated channel cache', () {
      final context = TestFactory.fastContext();
      final command = ListCommand(context);
      final releases = FakeFlutterReleaseClient.loadFixtureReleases();
      const cachedStable = CacheFlutterVersion(
        'stable',
        type: VersionType.channel,
        directory: '/cache/versions/stable',
        flutterSdkVersion: '3.10.0',
        dartSdkVersion: '3.0.0',
        isSetup: true,
      );

      command.displayVersionsTable(
        [cachedStable],
        releases,
        null,
        null,
      );

      final output = context.get<Logger>().outputs.join('\n');
      expect(output, contains('3.10.0'));
      expect(output, contains('→'));
      expect(output, contains('3.10.5'));
    });

    test('explains an empty cache without a malformed sentence', () async {
      final runner = TestFactory.fastCommandRunner();

      expect(
        await runner.runOrThrow(['fvm', 'list']),
        ExitCode.success.code,
      );

      final output = runner.context.get<Logger>().outputs.join('\n');
      expect(
        output,
        contains(
          'No SDKs have been installed yet. Flutter SDKs installed outside '
          'of FVM will not be displayed.',
        ),
      );
      expect(output, isNot(contains('Flutter. SDKs')));
    });
  });
}
