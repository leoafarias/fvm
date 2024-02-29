import 'package:fvm/src/models/config_model.dart';
import 'package:test/test.dart';

void main() {
  group('person test', () {
    test(
      '',
      () {
        final appConfig = AppConfig(
          cachePath: 'cachePath',
          flutterUrl: 'flutterUrl',
          useGitCache: true,
        );

        final newConfig = appConfig.copyWith(
          cachePath: 'newCachePath',
          flutterUrl: 'newFlutterUrl',
          useGitCache: null,
        );

        expect(newConfig.cachePath, 'newCachePath');
        expect(newConfig.flutterUrl, 'newFlutterUrl');
        expect(newConfig.useGitCache, true);
      },
    );
  });
}
