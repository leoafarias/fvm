import 'package:fvm/src/utils/convert_posix_path.dart';
import 'package:test/test.dart';

void main() {
  group('toPosixSeparator', () {
    test('Converts standard Windows path to POSIX path', () {
      expect(convertToPosixPath('C:\\Users\\Name\\Documents'),
          equals('C:/Users/Name/Documents'));
    });

    test('Leaves POSIX path unchanged', () {
      expect(convertToPosixPath('C:/Users/Name/Documents'),
          equals('C:/Users/Name/Documents'));
    });

    test('Handles empty string', () {
      expect(convertToPosixPath(''), equals(''));
    });

    test('Handles path with no backslashes', () {
      expect(convertToPosixPath('C:/Users/Name/Documents'),
          equals('C:/Users/Name/Documents'));
    });

    test('Converts mixed separator path correctly', () {
      expect(convertToPosixPath('C:/Users\\Name/Documents'),
          equals('C:/Users/Name/Documents'));
    });

    test('Handles path with special characters and spaces', () {
      expect(convertToPosixPath('C:\\Users\\New Folder\\Documents'),
          equals('C:/Users/New Folder/Documents'));
    });

    test('Leaves macOS root path unchanged', () {
      expect(convertToPosixPath('/'), equals('/'));
    });

    test('Leaves Linux home directory path unchanged', () {
      expect(convertToPosixPath('/home/username'), equals('/home/username'));
    });

    test('Leaves macOS application path unchanged', () {
      expect(convertToPosixPath('/Applications/Utilities'),
          equals('/Applications/Utilities'));
    });

    test('Leaves Linux system path unchanged', () {
      expect(convertToPosixPath('/usr/bin'), equals('/usr/bin'));
    });

    test('Handles mixed content path with POSIX format', () {
      expect(convertToPosixPath('/var/log/apache2/access.log'),
          equals('/var/log/apache2/access.log'));
    });
  });
}
