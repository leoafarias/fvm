import 'dart:io';

import 'package:fvm/fvm.dart';
import 'package:fvm/src/services/flutter_service.dart';

import 'fake_flutter_sdk_fixture.dart';

/// Fixture-backed Flutter SDK behavior for fast tests.
class FakeFlutterService extends FlutterService {
  FakeFlutterService(super.context);

  final installedVersions = <FlutterVersion>[];
  final setupVersions = <String>[];
  final pubGetCalls = <({String version, bool offline})>[];
  final runCalls = <({String cmd, List<String> args, String version})>[];

  final installFailures = <String, Exception>{};
  final runResults = <String, ProcessResult>{};

  static final _allowedReleases = <String>{
    '2.0.0',
    '2.2.0',
    '2.2.2',
    '3.0.0',
    '3.10.0',
    '3.10.5',
    '3.19.0',
    '1.12.0',
    '3.19.0@beta',
  };

  static final _allowedForkRefs = <String>{
    'leo-test-21',
  };

  static final _commitHashPattern =
      RegExp(r'^[0-9a-f]{7,40}$', caseSensitive: false);

  @override
  Future<void> install(FlutterVersion version) async {
    final key = version.nameWithAlias;
    final failure = installFailures[key] ?? installFailures[version.name];
    if (failure != null) throw failure;

    if (!_canInstall(version)) {
      throw AppException(
        'Failed to clone Flutter repository with version "${version.version}".\n'
        'The branch or tag was not found in the upstream repository.\n'
        'Repository URL: ${context.flutterUrl}',
      );
    }

    installedVersions.add(version);
    FakeFlutterSdkFixture.install(
      context,
      version,
      state: FakeFlutterSdkState.installedNotSetup,
    );
  }

  bool _canInstall(FlutterVersion version) {
    if (version.isChannel) return true;

    if (version.fromFork) {
      final forkConfigured = context.config.forks.any(
        (fork) => fork.name == version.fork,
      );

      return forkConfigured && _allowedForkRefs.contains(version.version);
    }

    if (version.isUnknownRef) {
      return _commitHashPattern.hasMatch(version.version);
    }

    if (version.isRelease) {
      final normalized = version.version.startsWith('v')
          ? version.version.substring(1)
          : version.version;

      return _allowedReleases.contains(version.name) ||
          _allowedReleases.contains(normalized) ||
          _allowedReleases.contains(version.version);
    }

    return false;
  }

  @override
  Future<ProcessResult> setup(CacheFlutterVersion version) async {
    setupVersions.add(version.name);

    final cacheVersion = FakeFlutterSdkFixture.install(
      context,
      version.toFlutterVersion(),
      state: FakeFlutterSdkState.installedSetup,
    );

    return _successResult(_flutterVersionOutput(cacheVersion));
  }

  @override
  Future<ProcessResult> pubGet(
    CacheFlutterVersion version, {
    bool throwOnError = false,
    bool offline = false,
  }) async {
    pubGetCalls.add((version: version.name, offline: offline));

    return _successResult('');
  }

  @override
  Future<ProcessResult> run(
    String cmd,
    List<String> args,
    CacheFlutterVersion version, {
    bool throwOnError = false,
    bool? echoOutput,
  }) async {
    runCalls.add((cmd: cmd, args: args, version: version.name));

    final key = '$cmd ${args.join(' ')} ${version.name}';
    final configured = runResults[key];
    if (configured != null) return configured;

    if (cmd == 'flutter' && args.contains('--version')) {
      return _successResult(_flutterVersionOutput(version));
    }

    if (cmd == 'dart' && args.contains('--version')) {
      return _successResult(
        'Dart SDK version: ${version.dartSdkVersion ?? _fixtureFor(version).dartSdkVersion}\n',
      );
    }

    return _successResult('');
  }

  @override
  Future<ProcessResult> runFlutter(
    List<String> args,
    CacheFlutterVersion version,
  ) {
    return run('flutter', args, version);
  }

  FlutterRootVersionFixture _fixtureFor(CacheFlutterVersion version) {
    return FakeFlutterSdkFixture.loadFixture(
      FakeFlutterSdkFixture.resolveFixtureName(version.toFlutterVersion()),
    );
  }

  String _flutterVersionOutput(CacheFlutterVersion version) {
    final fixture = _fixtureFor(version);
    final flutterVersion =
        version.flutterSdkVersion ?? fixture.primaryFlutterVersion;
    final dartVersion = version.dartSdkVersion ?? fixture.dartSdkVersion;
    final channel =
        fixture.flutterVersionJson['channel'] as String? ?? 'stable';

    return '''
Flutter $flutterVersion • channel $channel • https://github.com/flutter/flutter.git
Framework • revision fake123456789
Engine • revision fake987654321
Tools • Dart $dartVersion • DevTools 2.48.0
''';
  }

  ProcessResult _successResult(String stdout) {
    return ProcessResult(0, 0, stdout, '');
  }
}
