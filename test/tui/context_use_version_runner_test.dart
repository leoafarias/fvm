import 'package:fvm/fvm.dart';
import 'package:fvm/src/tui/adapters/context_use_version_runner.dart';
import 'package:fvm/src/tui/adapters/fvm_context_handle.dart';
import 'package:fvm/src/workflows/ensure_cache.workflow.dart';
import 'package:fvm/src/workflows/use_version.workflow.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  test('pins a channel and passes every explicit project choice', () async {
    late _FakeEnsureCache ensure;
    late _FakeUseVersion use;
    final operationContext = TestFactory.fastContext(
      skipInput: true,
      generators: {
        EnsureCacheWorkflow: (context) => ensure = _FakeEnsureCache(context),
        UseVersionWorkflow: (context) => use = _FakeUseVersion(context),
      },
    );
    final runner = ContextUseVersionRunner(
      FvmContextHandle(operationContext, reload: (previous) => previous),
      operationContextFactory: (_) => operationContext,
    );
    final events = <String>[];

    await runner.run((
      version: 'stable',
      pin: true,
      runPubGet: false,
      updateVscode: false,
      updateMelos: true,
      force: true,
      flavor: 'production',
    ), events.add);

    expect(ensure.requested.name, '3.10.5');
    expect(use.skipPubGet, isTrue);
    expect(use.updateVscodeSettings, isFalse);
    expect(use.updateMelosSettings, isTrue);
    expect(use.configureMissingMelos, isTrue);
    expect(use.updateExistingMelos, isTrue);
    expect(use.force, isTrue);
    expect(use.flavor, 'production');
    expect(events, contains('ensuring 3.10.5'));
  });
}

final class _FakeEnsureCache extends EnsureCacheWorkflow {
  _FakeEnsureCache(super.context);

  late FlutterVersion requested;

  @override
  Future<CacheFlutterVersion> call(
    FlutterVersion version, {
    bool shouldInstall = false,
    bool force = false,
    int retryCount = 0,
  }) async {
    requested = version;
    logger.info('ensuring ${version.name}');

    return CacheFlutterVersion(
      version.name,
      releaseChannel: version.releaseChannel,
      type: version.type,
      fork: version.fork,
      directory: path.join(context.versionsCachePath, version.name),
      flutterSdkVersion: version.version,
      dartSdkVersion: '3.10.0',
      isSetup: true,
    );
  }
}

final class _FakeUseVersion extends UseVersionWorkflow {
  _FakeUseVersion(super.context);

  bool? skipPubGet;
  bool? updateVscodeSettings;
  bool? updateMelosSettings;
  bool? configureMissingMelos;
  bool? updateExistingMelos;
  bool? force;
  String? flavor;

  @override
  Future<void> call({
    required CacheFlutterVersion version,
    required Project project,
    bool force = false,
    bool skipSetup = false,
    bool skipPubGet = false,
    String? flavor,
    bool? updateVscodeSettings,
    bool? updateMelosSettings,
    bool? configureMissingMelos,
    bool? updateExistingMelos,
  }) async {
    this.skipPubGet = skipPubGet;
    this.updateVscodeSettings = updateVscodeSettings;
    this.updateMelosSettings = updateMelosSettings;
    this.configureMissingMelos = configureMissingMelos;
    this.updateExistingMelos = updateExistingMelos;
    this.force = force;
    this.flavor = flavor;
  }
}
