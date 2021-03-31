/// Model for valid Flutter versions.
/// User for type safety across FVM
class ValidVersion {
  /// Name of the version
  String name;

  /// Constructor
  ValidVersion(this.name);

  @override
  String toString() {
    return name;
  }
}
