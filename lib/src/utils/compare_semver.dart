import 'package:pub_semver/pub_semver.dart';

/// Compares two semantic version strings.
/// Returns -1, 0, or 1 for less than, equal, or greater than respectively.
/// Throws [FormatException] if either version is invalid.
int compareSemver(String version, String otherVersion) {
  // Parse the versions - throws FormatException if invalid
  final ver1 = Version.parse(version);
  final ver2 = Version.parse(otherVersion);

  // Use the built-in semantic version comparison
  if (ver1 < ver2) return -1;
  if (ver1 > ver2) return 1;

  return 0; // versions are equal
}
