import 'package:fvm_mcp/src/version.dart';
import 'package:test/test.dart';

void main() {
  test('parses semver', () {
    final v = const FvmVersion(3, 2, 1, '3.2.1');
    expect(v.supportsJsonApi, isTrue); // >= 3.1.2
    expect(v.supportsSkipInput, isTrue); // >= 3.2.0
  });

  test('gates for old versions', () {
    final v = const FvmVersion(3, 0, 0, '3.0.0');
    expect(v.supportsJsonApi, isFalse);
    expect(v.supportsSkipInput, isFalse);
  });
}
