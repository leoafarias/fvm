@Timeout(Duration(minutes: 5))
import 'package:fvm/fvm.dart';
import 'package:fvm/utils/config_utils.dart';
import 'package:test/test.dart';
import 'package:fvm/constants.dart';

final testPath = '$fvmHome/test_path';

void main() {
  tearDown(() async {
    ConfigUtils().removeConfig();
  });

  test('Run Install Channel', () async {
    try {
      await fvmRunner(['install', 'master']);
    } on Exception catch (e) {
      fail("Exception thrown, $e");
    }

    expect(true, true);
  });

  test('Run Install Release', () async {
    try {
      await fvmRunner(['install', '1.8.0']);
    } on Exception catch (e) {
      fail("Exception thrown, $e");
    }

    expect(true, true);
  });

  test('Run List command', () async {
    try {
      await fvmRunner(['list']);
    } on Exception catch (e) {
      fail("Exception thrown, $e");
    }

    expect(true, true);
  });

  test('Run Use command', () async {
    try {
      await fvmRunner(['use', 'master']);
    } on Exception catch (e) {
      fail("Exception thrown, $e");
    }

    expect(true, true);
  });

  test('Run Remove Channel', () async {
    try {
      await fvmRunner(['remove', 'master']);
    } on Exception catch (e) {
      fail("Exception thrown, $e");
    }

    expect(true, true);
  });

  test('Run Remove Release', () async {
    try {
      await fvmRunner(['remove', '1.8.0']);
    } on Exception catch (e) {
      fail("Exception thrown, $e");
    }

    expect(true, true);
  });

  test('Fail Run Flutter Command', () async {
    try {
      await fvmRunner(['flutter']);
      fail('Exception not thrown');
    } on Exception {
      expect(true, true);
    }
  });
  test('Gets config options without exception', () async {
    try {
      await fvmRunner(['config', '--ls']);
    } on Exception catch (e) {
      fail("Exception thrown, $e");
    }
    expect(true, true);
  });

  test('Sets Config cache-path', () async {
    try {
      await fvmRunner(['config', '--cache-path', testPath]);
    } on Exception catch (e) {
      fail("Exception thrown, $e");
    }
    expect(testPath, kVersionsDir.path);
  });
}
