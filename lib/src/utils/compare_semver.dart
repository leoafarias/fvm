import 'package:pub_semver/pub_semver.dart';

int compareSemver(String version, String otherVersion) {
  // Parse the versions
  // If version is not valid semver version, it will throw FormatException
  Version ver1 = Version.parse(version);
  Version ver2 = Version.parse(otherVersion);

  // Use the built-in comparison
  if (ver1 < ver2) return -1;
  if (ver1 > ver2) return 1;
  return 0; // versions are equal
}
