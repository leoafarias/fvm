// Model for valid Flutter versions.
// Mainly to have some type safety
class ValidVersion {
  String version;
  ValidVersion(this.version);

  @override
  String toString() {
    return version;
  }
}
