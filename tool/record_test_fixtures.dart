import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:fvm/src/models/flutter_root_version_file.dart';
import 'package:path/path.dart' as p;

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addCommand('flutter-version')
    ..addCommand('releases');

  parser.commands['flutter-version']!
    ..addOption('flutter-root', mandatory: true)
    ..addOption('name', mandatory: true)
    ..addOption(
      'output',
      defaultsTo: 'test/fixtures/flutter_root_versions',
    );

  parser.commands['releases']!
    ..addOption('source', mandatory: true)
    ..addOption('versions', mandatory: true)
    ..addOption('output', defaultsTo: 'test/fixtures/releases');

  final results = parser.parse(args);
  final command = results.command;

  if (command == null) {
    stderr.writeln(parser.usage);
    exitCode = 64;
    return;
  }

  switch (command.name) {
    case 'flutter-version':
      await _recordFlutterVersion(command);
    case 'releases':
      await _recordReleases(command);
    default:
      stderr.writeln(parser.usage);
      exitCode = 64;
  }
}

Future<void> _recordFlutterVersion(ArgResults command) async {
  final flutterRoot = Directory(command['flutter-root'] as String);
  final name = command['name'] as String;
  final outputDir = Directory(command['output'] as String);

  if (!flutterRoot.existsSync()) {
    stderr.writeln('Flutter root does not exist: ${flutterRoot.path}');
    exitCode = 66;
    return;
  }

  final rootMetadata = FlutterRootVersionFile.tryLoadFromRoot(flutterRoot);
  final legacyVersion = _readOptionalTrimmed(
        File(p.join(flutterRoot.path, 'version')),
      ) ??
      rootMetadata?.primaryVersion;
  final dartSdkVersionFile = File(
    p.join(flutterRoot.path, 'bin', 'cache', 'dart-sdk', 'version'),
  );
  final dartSdkVersion = _nonEmpty(rootMetadata?.dartSdkVersion) ??
      _readOptionalTrimmed(dartSdkVersionFile);
  final flutterVersionJson = rootMetadata?.toMap() ?? <String, dynamic>{};

  if (legacyVersion == null) {
    stderr.writeln(
      'No Flutter version metadata found under ${flutterRoot.path}. '
      'Expected a root version file or flutter.version.json with '
      'flutterVersion/frameworkVersion.',
    );
    exitCode = 66;
    return;
  }

  if (dartSdkVersion == null) {
    stderr.writeln(
      'No Dart SDK version metadata found under ${flutterRoot.path}. '
      'Expected flutter.version.json dartSdkVersion or '
      'bin/cache/dart-sdk/version.',
    );
    exitCode = 66;
    return;
  }

  final payload = _sortedMap({
    'name': name,
    'legacyVersion': legacyVersion,
    'dartSdkVersion': dartSdkVersion,
    'flutterVersionJson': _sortedMap(flutterVersionJson),
  });

  outputDir.createSync(recursive: true);
  final outputFile = File(p.join(outputDir.path, '$name.json'));
  outputFile.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(payload)}\n',
  );

  stdout.writeln('Wrote ${outputFile.path}');
}

String? _readOptionalTrimmed(File file) {
  if (!file.existsSync()) return null;

  return _nonEmpty(file.readAsStringSync());
}

String? _nonEmpty(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;

  return trimmed;
}

Future<void> _recordReleases(ArgResults command) async {
  final source = command['source'] as String;
  final versions = (command['versions'] as String)
      .split(',')
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList();
  final outputDir = Directory(command['output'] as String);

  final rawJson = await _readSourceJson(source);
  final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
  final releases = (decoded['releases'] as List)
      .whereType<Map<String, dynamic>>()
      .where((release) => versions.contains(release['version'] as String))
      .map(_normalizeRelease)
      .toList()
    ..sort(
      (a, b) => (a['version'] as String).compareTo(b['version'] as String),
    );

  if (releases.isEmpty) {
    stderr.writeln('No releases matched requested versions: $versions');
    exitCode = 66;
    return;
  }

  final releaseByHash = {
    for (final release in releases) release['hash'] as String: release,
  };

  final currentRelease = <String, String>{};
  for (final channel in ['stable', 'beta', 'dev']) {
    final match = releases.firstWhere(
      (release) =>
          release['channel'] == channel && release['active_channel'] == true,
      orElse: () => releases.firstWhere(
        (release) => release['channel'] == channel,
        orElse: () => <String, dynamic>{},
      ),
    );

    final hash = match['hash'] as String?;
    if (hash != null) {
      currentRelease[channel] = hash;
    }
  }

  for (final channel in ['stable', 'beta', 'dev']) {
    currentRelease.putIfAbsent(channel, () {
      final fallback = releases.firstWhere(
        (release) => release['channel'] == channel,
        orElse: () => releases.first,
      );

      return fallback['hash'] as String;
    });
  }

  final payload = _sortedMap({
    'base_url': decoded['base_url'],
    'current_release': _sortedMap(currentRelease),
    'releases': releases,
  });

  outputDir.createSync(recursive: true);
  final outputFile = File(p.join(outputDir.path, 'minimal_releases.json'));
  outputFile.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(payload)}\n',
  );

  stdout.writeln('Wrote ${outputFile.path}');
  stdout.writeln('Matched ${releases.length} release(s)');
  stdout.writeln('Hashes: ${releaseByHash.keys.join(', ')}');
}

Future<String> _readSourceJson(String source) async {
  final uri = Uri.tryParse(source);
  if (uri != null && uri.hasScheme && uri.scheme.startsWith('http')) {
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('HTTP ${response.statusCode} for $source');
      }

      return await response.transform(utf8.decoder).join();
    } finally {
      client.close(force: true);
    }
  }

  final file = File(source);
  if (!file.existsSync()) {
    throw StateError('Source file does not exist: $source');
  }

  return file.readAsStringSync();
}

Map<String, dynamic> _normalizeRelease(Map<String, dynamic> release) {
  final normalized = <String, dynamic>{
    'archive': release['archive'],
    'channel': release['channel'],
    'hash': release['hash'],
    'release_date': release['release_date'],
    'sha256': release['sha256'],
    'version': release['version'],
  };

  final dartSdkVersion = release['dart_sdk_version'];
  if (dartSdkVersion != null) {
    normalized['dart_sdk_version'] = dartSdkVersion;
  }

  final dartSdkArch = release['dart_sdk_arch'];
  if (dartSdkArch != null) {
    normalized['dart_sdk_arch'] = dartSdkArch;
  }

  final activeChannel = release['active_channel'];
  if (activeChannel == true) {
    normalized['active_channel'] = true;
  }

  return _sortedMap(normalized);
}

Map<String, dynamic> _sortedMap(Map<String, dynamic> source) {
  final keys = source.keys.toList()..sort();

  return {
    for (final key in keys)
      key: source[key] is Map<String, dynamic>
          ? _sortedMap(source[key] as Map<String, dynamic>)
          : source[key],
  };
}
