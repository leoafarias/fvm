import 'dart:io';

const _arm = 'arm';
const _arm64 = 'arm64';
const _ia32 = 'ia32';
const _x64 = 'x64';

/// Parsed release model
class ParsedReleases {
  /// Constructor
  const ParsedReleases({required this.channels, required this.releases});

  /// Channels
  final Map<String, dynamic> channels;

  /// Releases
  final List<dynamic> releases;
}

/// Goes through the current_release payload.
/// Finds the proper release base on the hash
/// Assings to the current_release
ParsedReleases parseCurrentReleases(Map<String, dynamic> json) {
  final currentRelease = json['current_release'] as Map<String, dynamic>;
  final releases = json['releases'] as List<dynamic>;

  final systemArch = 'x64';

  // Filter out channel/currentRelease versions
  // Could be more efficient
  for (var release in releases) {
    for (var current in currentRelease.entries) {
      if (current.value == release['hash'] &&
          current.key == release['channel']) {
        currentRelease[current.key] = release;
        release['activeChannel'] = true;
      }
    }
  }

  if (Platform.isMacOS) {
    // Filter out releases based on architecture
    // Remove if architecture is not compatible
    releases.removeWhere((release) {
      final arch = release['dart_sdk_arch'];
      final isActiveChanel = release['activeChannel'] == true;
      return arch != systemArch && arch != null && !isActiveChanel;
    });
  }

  return ParsedReleases(
    channels: currentRelease,
    releases: releases,
  );
}

// https://stackoverflow.com/questions/45125516/possible-values-for-uname-m
final _unames = {
  'arm': _arm,
  'arm64': _arm64,
  'aarch64_be': _arm64,
  'aarch64': _arm64,
  'armv8b': _arm64,
  'armv8l': _arm64,
  'i386': _ia32,
  'i686': _ia32,
  'x86_64': _x64,
};

String _architecture() {
  final uname = Process.runSync('uname', ['-m']).stdout as String;
  final trimmedName = uname.trim();
  final architecture = _unames[trimmedName];
  if (architecture == null) {
    throw Exception('Unrecognized architecture: "$trimmedName"');
  }

  return architecture;
}
