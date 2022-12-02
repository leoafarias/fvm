import 'dart:io';

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
