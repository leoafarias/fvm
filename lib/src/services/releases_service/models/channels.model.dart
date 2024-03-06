import 'package:dart_mappable/dart_mappable.dart';

part 'channels.model.mapper.dart';

/// Enum of a channel
@MappableEnum()
enum FlutterChannel {
  stable,
  dev,
  beta,
  master;

  const FlutterChannel();

  /// Returns a channel from a name
  static FlutterChannel fromName(String name) {
    if (name == FlutterChannel.stable.name) return FlutterChannel.stable;
    if (name == FlutterChannel.dev.name) return FlutterChannel.dev;
    if (name == FlutterChannel.beta.name) return FlutterChannel.beta;
    if (name == FlutterChannel.master.name) return FlutterChannel.master;
    throw Exception('Invalid Channel name: $name');
  }
}
