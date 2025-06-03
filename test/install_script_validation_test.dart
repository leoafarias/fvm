import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

void main() {
  group('Install Script Validation:', () {
    test('Local install.sh matches public version', () async {
      // Read the local install script
      final localScript = File('scripts/install.sh');
      expect(localScript.existsSync(), true,
          reason: 'Local install.sh script should exist');

      final localContent = await localScript.readAsString();

      // Fetch the public version from GitHub
      const publicUrl =
          'https://raw.githubusercontent.com/leoafarias/fvm/main/scripts/install.sh';
      final response = await http.get(Uri.parse(publicUrl));

      expect(response.statusCode, 200,
          reason: 'Public install.sh should be accessible');

      final publicContent = response.body;

      // Compare the contents
      expect(localContent.trim(), equals(publicContent.trim()),
          reason: 'Local install.sh should match the public version on GitHub');
    });

    test('Local uninstall.sh matches public version', () async {
      // Read the local uninstall script
      final localScript = File('scripts/uninstall.sh');
      expect(localScript.existsSync(), true,
          reason: 'Local uninstall.sh script should exist');

      final localContent = await localScript.readAsString();

      // Fetch the public version from GitHub
      const publicUrl =
          'https://raw.githubusercontent.com/leoafarias/fvm/main/scripts/uninstall.sh';
      final response = await http.get(Uri.parse(publicUrl));

      expect(response.statusCode, 200,
          reason: 'Public uninstall.sh should be accessible');

      final publicContent = response.body;

      // Compare the contents
      expect(localContent.trim(), equals(publicContent.trim()),
          reason:
              'Local uninstall.sh should match the public version on GitHub');
    });

    test('Local install.sh matches docs/public version', () async {
      // Read the local script
      final localScript = File('scripts/install.sh');
      expect(localScript.existsSync(), true,
          reason: 'Local install.sh script should exist');

      final localContent = await localScript.readAsString();

      // Read the docs/public version
      final publicScript = File('docs/public/install.sh');
      expect(publicScript.existsSync(), true,
          reason: 'Public install.sh script should exist in docs/public');

      final publicContent = await publicScript.readAsString();

      // Compare the contents
      expect(localContent.trim(), equals(publicContent.trim()),
          reason: 'Local install.sh should match the docs/public version');
    });

    test('Local uninstall.sh matches docs/public version', () async {
      // Read the local script
      final localScript = File('scripts/uninstall.sh');
      expect(localScript.existsSync(), true,
          reason: 'Local uninstall.sh script should exist');

      final localContent = await localScript.readAsString();

      // Read the docs/public version
      final publicScript = File('docs/public/uninstall.sh');
      expect(publicScript.existsSync(), true,
          reason: 'Public uninstall.sh script should exist in docs/public');

      final publicContent = await publicScript.readAsString();

      // Compare the contents
      expect(localContent.trim(), equals(publicContent.trim()),
          reason: 'Local uninstall.sh should match the docs/public version');
    });

    test('Dockerfile uses correct install script URL', () async {
      // Read the Dockerfile
      final dockerfile = File('.docker/Dockerfile');
      expect(dockerfile.existsSync(), true, reason: 'Dockerfile should exist');

      final dockerfileContent = await dockerfile.readAsString();

      // Check that it uses the correct URL
      const expectedUrl =
          'https://raw.githubusercontent.com/leoafarias/fvm/main/scripts/install.sh';
      expect(dockerfileContent.contains(expectedUrl), true,
          reason:
              'Dockerfile should reference the correct public install script URL');
    });

    test('Grinder task moves scripts to correct location', () async {
      // This is more of a smoke test to ensure the grinder task is properly defined
      final grinderFile = File('tool/grind.dart');
      expect(grinderFile.existsSync(), true,
          reason: 'Grinder file should exist');

      final grinderContent = await grinderFile.readAsString();

      // Check that the moveScripts task is defined
      expect(
          grinderContent
              .contains('Move install.sh and uninstall.sh to public directory'),
          true,
          reason:
              'Grinder should have a task to move scripts to public directory');

      expect(grinderContent.contains("File('scripts/install.sh')"), true,
          reason: 'Grinder should reference the local install script');

      expect(grinderContent.contains("path.join(publicDir.path, 'install.sh')"),
          true,
          reason: 'Grinder should copy to the public directory');
    });
  });
}
