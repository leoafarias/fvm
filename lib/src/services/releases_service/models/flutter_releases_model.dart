import 'dart:convert';
import 'dart:ffi';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:meta/meta.dart';

import '../../../models/flutter_version_model.dart';
import '../../../utils/exceptions.dart';
import 'version_model.dart';

part 'flutter_releases_model.mapper.dart';

const _flutterChannels = ['stable', 'beta', 'dev'];

/// Flutter Releases
@MappableClass()
class FlutterReleasesResponse with FlutterReleasesResponseMappable {
  /// Base url for Flutter   /// Channels in Flutter releases
  final String baseUrl;

  /// Channels in Flutter releases
  final Channels channels;

  /// LIst of all releases
  final List<FlutterSdkRelease> versions;

  /// Version release map
  final Map<String, FlutterSdkRelease> _versionReleaseMap;

  const FlutterReleasesResponse({
    required this.baseUrl,
    required this.channels,
    required this.versions,
    required Map<String, FlutterSdkRelease> versionReleaseMap,
  }) : _versionReleaseMap = versionReleaseMap;

  /// Creates a FlutterRelease from a [json] string
  factory FlutterReleasesResponse.fromJson(String json) {
    return FlutterReleasesResponse.fromMap(
      jsonDecode(json) as Map<String, dynamic>,
    );
  }

  /// Create FlutterRelease from a map of values
  factory FlutterReleasesResponse.fromMap(Map<String, dynamic> json) {
    return _parseCurrentReleases(json, Abi.current());
  }

  /// Create FlutterRelease from a map using an explicit platform ABI.
  @visibleForTesting
  factory FlutterReleasesResponse.fromMapForTesting(
    Map<String, dynamic> json, {
    required Abi abi,
  }) {
    return _parseCurrentReleases(json, abi);
  }

  /// Returns a [FlutterVersion] release from channel [version]
  FlutterSdkRelease latestChannelRelease(String channel) {
    if (!_flutterChannels.contains(channel)) {
      throw Exception('Can only infer release on valid channel');
    }

    return channels[channel];
  }

  /// Retrieves version information
  FlutterSdkRelease? fromVersion(String version) {
    return _versionReleaseMap[version];
  }

  /// Checks if version is a release
  bool containsVersion(String version) {
    return _versionReleaseMap.containsKey(version);
  }
}

/// Goes through the current_release payload.
/// Finds the proper release base on the hash
/// Assigns to the current_release
FlutterReleasesResponse _parseCurrentReleases(
  Map<String, dynamic> map,
  Abi abi,
) {
  final baseUrlValue = map['base_url'];
  if (baseUrlValue is! String || baseUrlValue.isEmpty) {
    throw AppException('Invalid releases data: missing base_url');
  }
  final baseUrl = baseUrlValue;

  final currentReleaseValue = map['current_release'];
  if (currentReleaseValue is! Map<String, dynamic>) {
    throw AppException('Invalid releases data: missing current_release');
  }
  final currentRelease = currentReleaseValue;

  final releasesValue = map['releases'];
  if (releasesValue is! List) {
    throw AppException('Invalid releases data: missing releases list');
  }
  final releasesJson = releasesValue.whereType<Map<String, dynamic>>().toList();
  if (releasesJson.length != releasesValue.length) {
    throw AppException(
      'Invalid releases data: release entries must be objects',
    );
  }

  final preferredArch = _preferredArchiveArchitecture(abi);
  final availableArchitectures =
      _availableArchitecturesByReleaseKey(releasesJson);

  final releasesList = <FlutterSdkRelease>[];
  final versionReleaseMap = <String, FlutterSdkRelease>{};
  final hashReleaseMap = <String, FlutterSdkRelease>{};

  // Filter out channel/currentRelease versions
  // Could be more efficient
  for (var release in releasesJson) {
    for (var current in currentRelease.entries) {
      final channelName = current.key;
      final releaseHash = current.value;
      if (releaseHash == release['hash'] && channelName == release['channel']) {
        release['active_channel'] = true;
      }
    }

    // Prefer the native archive when Flutter publishes more than one archive
    // for the same logical release. If there is no native archive row, keep the
    // foreign-arch row: FVM installs by git clone (the archive URL is never
    // downloaded), so this metadata also drives installable-version lookups
    // and dropping it would hide versions that install fine.
    if (!_shouldKeepReleaseForPlatform(
      release,
      preferredArch: preferredArch,
      availableArchitectures: availableArchitectures,
    )) {
      continue;
    }

    final releaseItem = FlutterSdkRelease.fromMap(release);

    /// Add to releases
    releasesList.add(releaseItem);
    versionReleaseMap[releaseItem.version] = releaseItem;
    hashReleaseMap[releaseItem.hash] = releaseItem;
  }

  final dev = currentRelease['dev'] as String?;
  final beta = currentRelease['beta'] as String?;
  final stable = currentRelease['stable'] as String?;

  if (dev == null || beta == null || stable == null) {
    throw AppException('Invalid releases data: missing release channels');
  }

  final devRelease = hashReleaseMap[dev];
  final betaRelease = hashReleaseMap[beta];
  final stableRelease = hashReleaseMap[stable];

  if (devRelease == null || betaRelease == null || stableRelease == null) {
    throw AppException('Invalid releases data: missing channel releases');
  }

  final channels = Channels(
    beta: betaRelease,
    dev: devRelease,
    stable: stableRelease,
  );

  return FlutterReleasesResponse(
    baseUrl: baseUrl,
    channels: channels,
    versions: releasesList,
    versionReleaseMap: versionReleaseMap,
  );
}

Map<String, Set<String>> _availableArchitecturesByReleaseKey(
  List<Map<String, dynamic>> releasesJson,
) {
  final architecturesByKey = <String, Set<String>>{};

  for (final release in releasesJson) {
    final arch = release['dart_sdk_arch'];
    if (arch is! String) continue;

    architecturesByKey
        .putIfAbsent(_releaseArchitectureKey(release), () => <String>{})
        .add(arch);
  }

  return architecturesByKey;
}

String _releaseArchitectureKey(Map<String, dynamic> release) {
  return '${release['hash']}|${release['channel']}|${release['version']}';
}

bool _shouldKeepReleaseForPlatform(
  Map<String, dynamic> release, {
  required String? preferredArch,
  required Map<String, Set<String>> availableArchitectures,
}) {
  if (preferredArch == null) return true;

  final arch = release['dart_sdk_arch'];
  if (arch == null || arch == preferredArch) return true;

  final architectures =
      availableArchitectures[_releaseArchitectureKey(release)];

  return architectures == null || !architectures.contains(preferredArch);
}

/// Only macOS and Windows publish per-architecture release rows; every other
/// ABI falls through to null, which disables the preference filter.
String? _preferredArchiveArchitecture(Abi abi) {
  // The ABI reflects the Dart VM architecture, not native hardware: under
  // Rosetta 2 or Windows x64 emulation this reports x64 even on ARM64 hosts.
  switch (abi) {
    case Abi.macosArm64:
    case Abi.windowsArm64:
      return 'arm64';
    case Abi.macosX64:
    case Abi.windowsX64:
      return 'x64';
    default:
      return null;
  }
}
