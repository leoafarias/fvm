import 'package:fvm/src/models/project_registry_model.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectRegistryDocument', () {
    test('writes projects and flavors in deterministic order', () {
      final firstSeen = DateTime.utc(2026, 8, 21, 18, 15);
      final lastSeen = DateTime.utc(2026, 8, 21, 19, 30);
      final document = ProjectRegistryDocument(
        schemaVersion: 1,
        projects: [
          ProjectRegistryEntry(
            path: '/z/app',
            name: 'z',
            flutter: 'stable',
            flavors: const {'legacy': '3.19.6', 'beta': 'beta'},
            firstSeenAt: firstSeen,
            lastSeenAt: lastSeen,
          ),
          ProjectRegistryEntry(
            path: '/a/app',
            name: 'a',
            flutter: 'beta',
            flavors: const {},
            firstSeenAt: firstSeen,
            lastSeenAt: lastSeen,
          ),
        ],
      );

      expect(
        document.toStorageJson(),
        equals(document.toStorageJson()),
      );
      expect(
        document.toStorageMap()['projects'],
        equals([
          {
            'path': '/a/app',
            'name': 'a',
            'flutter': 'beta',
            'flavors': <String, String>{},
            'firstSeenAt': '2026-08-21T18:15:00.000Z',
            'lastSeenAt': '2026-08-21T19:30:00.000Z',
          },
          {
            'path': '/z/app',
            'name': 'z',
            'flutter': 'stable',
            'flavors': {'beta': 'beta', 'legacy': '3.19.6'},
            'firstSeenAt': '2026-08-21T18:15:00.000Z',
            'lastSeenAt': '2026-08-21T19:30:00.000Z',
          },
        ]),
      );
    });
  });
}
