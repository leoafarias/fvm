import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('Install Script Validation:', () {
    test('install.sh exists in docs/public', () async {
      final publicScript = File('docs/public/install.sh');
      expect(
        publicScript.existsSync(),
        isTrue,
        reason: 'install.sh should exist in docs/public',
      );

      final content = await publicScript.readAsString();
      expect(
        content.contains('FVM Installer'),
        isTrue,
        reason: 'install.sh should contain FVM Installer header',
      );
    });

    test('uninstall.sh exists in docs/public', () async {
      final publicScript = File('docs/public/uninstall.sh');
      expect(
        publicScript.existsSync(),
        isTrue,
        reason: 'uninstall.sh should exist in docs/public',
      );
    });

    test('Dockerfile uses correct install script URL', () async {
      final dockerfile = File('.docker/Dockerfile');
      expect(dockerfile.existsSync(), isTrue, reason: 'Dockerfile should exist');

      final dockerfileContent = await dockerfile.readAsString();

      const expectedUrl =
          'https://raw.githubusercontent.com/leoafarias/fvm/main/docs/public/install.sh';
      expect(
        dockerfileContent.contains(expectedUrl),
        isTrue,
        reason:
            'Dockerfile should reference the docs/public install script URL',
      );
    });
  });
}
