import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:test/test.dart';

void main() {
  group('FlutterVersion model', () {
    test('compareTo', () async {
      const unsortedList = [
        'dev',
        '1.20.0',
        '1.22.0-1.0.pre',
        '1.3.1',
        'stable',
        'beta',
        '1.21.0-9.1.pre',
        'master',
        '2.0.0'
      ];
      const sortedList = [
        'master',
        'stable',
        'beta',
        'dev',
        '2.0.0',
        '1.22.0-1.0.pre',
        '1.21.0-9.1.pre',
        '1.20.0',
        '1.3.1'
      ];

      final versionUnsorted = unsortedList.map(FlutterVersion.parse).toList();
      versionUnsorted.sort((a, b) => a.compareTo(b));

      final afterUnsorted =
          versionUnsorted.reversed.map((e) => e.name).toList();

      expect(afterUnsorted, sortedList);
    });
  });
}
