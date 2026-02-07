import 'package:dart_mcp/server.dart';

List<String> flag(CallToolRequest call, String key, String cliFlag) {
  final v = (call.arguments ?? const {})[key];

  return v == true ? <String>[cliFlag] : const <String>[];
}

List<String> opt<T>(
  CallToolRequest call,
  String key,
  List<String> Function(T v) build,
) {
  final args = call.arguments ?? const {};
  if (args.containsKey(key) && args[key] != null) {
    final v = args[key];
    if (v is T) {
      return build(v);
    }
    throw ArgumentError.value(v, key, 'Expected $T');
  }

  return const <String>[];
}

List<String> maybeOne(CallToolRequest call, String key) {
  final v = stringArg(call, key);

  return (v != null && v.isNotEmpty) ? <String>[v] : const <String>[];
}

String? stringArg(CallToolRequest call, String key) {
  final v = (call.arguments ?? const {})[key];

  return (v is String && v.isNotEmpty) ? v : null;
}

bool? boolArg(CallToolRequest call, String key) {
  final v = (call.arguments ?? const {})[key];

  return (v is bool) ? v : null;
}

List<String> listArg(CallToolRequest call, String key) {
  final v = (call.arguments ?? const {})[key];

  return (v is List) ? v.whereType<String>().toList() : const <String>[];
}
