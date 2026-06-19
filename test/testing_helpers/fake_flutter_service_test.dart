import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  group('FakeFlutterService', () {
    test('installable releases include the versions the fast suite needs', () {
      final allowed = FakeFlutterService.allowedReleaseVersions;

      expect(allowed, isNotEmpty);
      // Versions exercised by the fast command/install tests. They must stay
      // recorded in minimal_releases.json so the fakes can resolve them; this
      // fails loudly if the fixture is trimmed.
      expect(
        allowed,
        containsAll(<String>[
          '3.10.0',
          '3.10.5',
          '3.19.0',
          '3.19.0@beta',
          '2.0.0',
          '2.2.2',
        ]),
      );
    });
  });
}
