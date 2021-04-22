import '../../constants.dart';

/// Model for valid Flutter versions.
/// User for type safety across FVM
class ValidVersion {
  /// Name of the version
  String name;

  /// Is custom version
  bool custom;

  /// Constructor
  ValidVersion(
    this.name, {
    this.custom = false,
  });

  /// Is valid version a channel
  bool get isChannel {
    return kFlutterChannels.contains(name);
  }

  /// Is valid version is master channel
  bool get isMaster {
    return name == 'master';
  }

  @override
  String toString() {
    return name;
  }
}
