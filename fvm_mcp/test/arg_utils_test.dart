import 'package:dart_mcp/server.dart';
import 'package:fvm_mcp/src/arg_utils.dart';
import 'package:test/test.dart';

CallToolRequest _req(Map<String, Object?> a) =>
    CallToolRequest(name: 't', arguments: a);

void main() {
  test('flag / opt / maybeOne', () {
    final r = _req({'compress': true, 'limit': 10, 'version': 'stable'});
    expect(flag(r, 'compress', '--compress'), equals(['--compress']));
    expect(opt<int>(r, 'limit', (v) => ['--limit', '$v']),
        equals(['--limit', '10']));
    expect(maybeOne(r, 'version'), equals(['stable']));
    expect(maybeOne(_req({}), 'version'), isEmpty);
  });

  test('string/list/bool args', () {
    final r = _req({
      'cwd': '/tmp',
      'args': ['--version'],
      'all': true
    });
    expect(stringArg(r, 'cwd'), '/tmp');
    expect(listArg(r, 'args'), equals(['--version']));
    expect(boolArg(r, 'all'), isTrue);
  });
}
