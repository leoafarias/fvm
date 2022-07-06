import 'dart:io';

const arm = 'arm';
const arm64 = 'arm64';
const ia32 = 'ia32';
const x64 = 'x64';

/// Goes through the current_release payload.
/// Finds the proper release base on the hash
/// Assings to the current_release
Map<String, dynamic> parseCurrentReleases(Map<String, dynamic> json) {
  final currentRelease = json['current_release'] as Map<String, dynamic>;
  final releases = json['releases'] as List<dynamic>;

  final systemArch = _architecture();

  if (Platform.isMacOS) {
    // Filter out releases based on architecture
    // Remove if architecture is not compatible
    releases.removeWhere((release) {
      final arch = release['dart_sdk_arch'];
      return arch != systemArch && arch != null;
    });
  }

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

  return currentRelease;
}

// https://stackoverflow.com/questions/45125516/possible-values-for-uname-m
final _unames = {
  'arm': arm,
  'arm64': arm64,
  'aarch64_be': arm64,
  'aarch64': arm64,
  'armv8b': arm64,
  'armv8l': arm64,
  'i386': ia32,
  'i686': ia32,
  'x86_64': x64,
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
