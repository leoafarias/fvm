/// Goes through the current_release payload.
/// Finds the proper release base on the hash
/// Assings to the current_release
Map<String, dynamic> parseCurrentReleases(Map<String, dynamic> json) {
  final currentRelease = json['current_release'] as Map<String, dynamic>;
  final releases = json['releases'] as List<dynamic>;

  // Filter out channel/currentRelease versions
  releases.forEach((release) {
    // Check if release hash is in hashmap
    currentRelease.entries.forEach((channel) {
      if (channel.value == release['hash'] &&
          channel.key == release['channel']) {
        currentRelease[channel.key] = release;
        release['activeChannel'] = true;
      }
    });
  });

  return currentRelease;
}
