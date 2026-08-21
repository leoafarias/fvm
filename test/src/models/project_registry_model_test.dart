import 'package:fvm/src/models/project_registry_model.dart';
import 'package:fvm/src/utils/exceptions.dart';
import 'package:test/test.dart';

void main() {
  const registryPath = '/cache/projects.json';

  group('encodeProjectRegistry', () {
    test('writes paths in deterministic sorted order', () {
      expect(
        encodeProjectRegistry(['/z/app', '/a/app']),
        encodeProjectRegistry(['/a/app', '/z/app']),
      );
      expect(
        parseProjectRegistry(
          encodeProjectRegistry(['/z/app', '/a/app']),
          registryPath: registryPath,
        ),
        ['/a/app', '/z/app'],
      );
    });
  });

  group('parseProjectRegistry', () {
    test('rejects documents it cannot safely rewrite', () {
      const cases = [
        'not-json',
        '[]',
        '{"projects":[]}',
        '{"schemaVersion":0,"projects":[]}',
        '{"schemaVersion":2,"projects":[]}',
        '{"schemaVersion":1}',
        '{"schemaVersion":1,"projects":{}}',
        '{"schemaVersion":1,"projects":[{"path":"/a"}]}',
        '{"schemaVersion":1,"projects":[""]}',
      ];

      for (final contents in cases) {
        expect(
          () => parseProjectRegistry(contents, registryPath: registryPath),
          throwsA(
            isA<ProjectRegistryException>().having(
              (error) => error.message,
              'message',
              contains(registryPath),
            ),
          ),
          reason: contents,
        );
      }
    });
  });
}
