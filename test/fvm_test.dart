@Timeout(Duration(minutes: 5))

import 'package:fvm/fvm.dart';
import 'package:test/test.dart';

void main() {
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
      fail("Exception not thrown, $e");
    }

    expect(true, true);
  });

  test('Run List command', () async {
    try {
      await fvmRunner(['list']);
    } on Exception catch (e) {
      fail("Exception not thrown, $e");
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

  test('Run Flutter Command Fails', () async {
    try {
      await fvmRunner(['flutter']);
      fail("Exception not thrown");
    } on Exception {
      expect(true, true);
    }
  });
}
