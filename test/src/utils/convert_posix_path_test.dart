import 'package:fvm/src/utils/convert_posix_path.dart';
import 'package:test/test.dart';

void main() {
  group('convertToPosixPath', () {
    final cases = <String, String>{
      'C\\Users\\Name\\Documents': 'C/Users/Name/Documents',
      'C:/Users/Name/Documents': 'C:/Users/Name/Documents',
      '': '',
      'C:/Users\\Name/Documents': 'C:/Users/Name/Documents',
      'C\\Users\\New Folder\\Documents': 'C/Users/New Folder/Documents',
      '/': '/',
      '/home/username': '/home/username',
      '/Applications/Utilities': '/Applications/Utilities',
      '/usr/bin': '/usr/bin',
      '/var/log/apache2/access.log': '/var/log/apache2/access.log',
    };

    cases.forEach((input, expected) {
      test('converts "$input"', () {
        expect(convertToPosixPath(input), equals(expected));
      });
    });
  });
}
