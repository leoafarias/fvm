import 'package:fvm_mcp/src/version.dart';
import 'package:test/test.dart';

void main() {
  test('parses semver', () {
    final v = parseFvmVersionOutput('3.2.1');
    expect(v.supportsJsonApi, isTrue); // >= 3.1.2
    expect(v.supportsSkipInput, isTrue); // >= 3.2.0
  });

  test('gates for old versions', () {
    final v = parseFvmVersionOutput('3.0.0');
    expect(v.supportsJsonApi, isFalse);
    expect(v.supportsSkipInput, isFalse);
  });

  test('prerelease does not satisfy exact stable threshold', () {
    final v = parseFvmVersionOutput('3.2.0-rc.1');
    expect(v.supportsJsonApi, isTrue); // > 3.1.2
    expect(v.supportsSkipInput, isFalse); // prerelease of 3.2.0
  });

  test('parseFvmVersionOutput handles prefixed version text', () {
    final v = parseFvmVersionOutput('FVM version: v4.0.5+hotfix.1');
    expect(v.major, 4);
    expect(v.minor, 0);
    expect(v.patch, 5);
    expect(v.raw, '4.0.5+hotfix.1');
  });

  test('parseFvmVersionOutput prefers inline version on FVM line', () {
    final v = parseFvmVersionOutput('''
FINE: Pub 3.10.1
FVM version: 4.0.5
''');
    expect(v.major, 4);
    expect(v.minor, 0);
    expect(v.patch, 5);
    expect(v.raw, '4.0.5');
  });

  test('parseFvmVersionOutput handles noisy output', () {
    final v = parseFvmVersionOutput('''
FINE: Pub 3.10.1
FINE: Package Config up to date.
4.0.5
IO  : writing logs...
''');
    expect(v.major, 4);
    expect(v.minor, 0);
    expect(v.patch, 5);
    expect(v.raw, '4.0.5');
  });

  test('parseFvmVersionOutput ignores non-FVM semver in logs', () {
    final v = parseFvmVersionOutput('''
FINE: Pub 3.10.1
FINE: Package Config up to date.
''');
    expect(v.isUnknown, isTrue);
  });

  test('parseFvmVersionOutput returns unknown when no semver is present', () {
    final v = parseFvmVersionOutput('''
something unexpected
no version here
''');
    expect(v.isUnknown, isTrue);
  });
}
