import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('Install Script Validation:', () {
    test('Local install.sh matches docs/public version', () async {
      // Read the local script
      final localScript = File('scripts/install.sh');
      expect(
        localScript.existsSync(),
        true,
        reason: 'Local install.sh script should exist',
      );

      final localContent = await localScript.readAsString();

      // Read the docs/public version
      final publicScript = File('docs/public/install.sh');
      expect(
        publicScript.existsSync(),
        true,
        reason: 'Public install.sh script should exist in docs/public',
      );

      final publicContent = await publicScript.readAsString();

      // Compare the contents
      expect(
        localContent.trim(),
        equals(publicContent.trim()),
        reason: 'Local install.sh should match the docs/public version',
      );
    });

    test('Local uninstall.sh matches docs/public version', () async {
      // Read the local script
      final localScript = File('scripts/uninstall.sh');
      expect(
        localScript.existsSync(),
        true,
        reason: 'Local uninstall.sh script should exist',
      );

      final localContent = await localScript.readAsString();

      // Read the docs/public version
      final publicScript = File('docs/public/uninstall.sh');
      expect(
        publicScript.existsSync(),
        isTrue,
        reason: 'Public uninstall.sh script should exist in docs/public',
      );

      final publicContent = await publicScript.readAsString();

      // Compare the contents
      expect(
        localContent.trim(),
        equals(publicContent.trim()),
        reason: 'Local uninstall.sh should match the docs/public version',
      );
    });

    test('Dockerfile uses correct install script URL', () async {
      // Read the Dockerfile
      final dockerfile = File('.docker/Dockerfile');
      expect(dockerfile.existsSync(), isTrue, reason: 'Dockerfile should exist');

      final dockerfileContent = await dockerfile.readAsString();

      // Check that it uses the correct URL
      const expectedUrl =
          'https://raw.githubusercontent.com/leoafarias/fvm/main/scripts/install.sh';
      expect(
        dockerfileContent.contains(expectedUrl),
        isTrue,
        reason:
            'Dockerfile should reference the correct public install script URL',
      );
    });

    test('Release grinder task moves scripts to correct location', () async {
      final grinderFile = File('tool/release_tool/tool/grind.dart');
      expect(
        grinderFile.existsSync(),
        isTrue,
        reason: 'Release grinder file should exist',
      );

      final grinderContent = await grinderFile.readAsString();

      expect(
        grinderContent.contains(
          "@Task('Move install scripts to public directory')",
        ),
        true,
        reason:
            'Release grinder should define a task for moving install scripts',
      );

      expect(
        grinderContent.contains("install.sh"),
        true,
        reason: 'Release grinder should reference install.sh',
      );

      expect(
        grinderContent.contains("docs/public"),
        true,
        reason: 'Release grinder should target the docs/public directory',
      );
    });
  });
}
