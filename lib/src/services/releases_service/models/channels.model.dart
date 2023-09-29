/// Enum of a channel
enum FlutterChannel {
  /// stable channel
  stable('stable'),

  /// dev channel
  dev('dev'),

  /// beta channel
  beta('beta'),

  master('master');

  const FlutterChannel(this.name);

  final String name;

  /// Returns a channel from a name
  static FlutterChannel fromName(String name) {
    if (name == FlutterChannel.stable.name) return FlutterChannel.stable;
    if (name == FlutterChannel.dev.name) return FlutterChannel.dev;
    if (name == FlutterChannel.beta.name) return FlutterChannel.beta;
    if (name == FlutterChannel.master.name) return FlutterChannel.master;
    throw Exception('Invalid Channel name: $name');
  }
}
