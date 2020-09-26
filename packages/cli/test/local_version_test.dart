import 'dart:io';

import 'package:fvm/constants.dart';
import 'package:fvm/fvm.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

void main() {
  test('Check function compareTo LocalVersion', () async {
    var unsortedList = [
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
    var sortedList = [
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

    final versionUnsorted =
        unsortedList.map((v) => LocalVersion(name: v)).toList();
    versionUnsorted.sort((a, b) => a.compareTo(b));

    final afterUnsorted = versionUnsorted.reversed.toList().map((e) => e.name);

    expect(afterUnsorted, sortedList);
  });

  test('Checks that install is not correct', () async {
    final invalidVersionName = 'INVALID_VERSION';
    final dir = Directory(join(kVersionsDir.path, invalidVersionName));
    await dir.create(recursive: true);
    final correct = await LocalVersionRepo.isInstalled(invalidVersionName);
    expect(correct, false);
  });
}
