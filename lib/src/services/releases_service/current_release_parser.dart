/// Goes through the current_release payload.
/// Finds the proper release base on the hash
/// Assings to the current_release
Map<String, dynamic> parseCurrentReleases(Map<String, dynamic> json) {
  final currentRelease = json['current_release'] as Map<String, dynamic>;
  final releases = json['releases'] as List<dynamic>;

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
