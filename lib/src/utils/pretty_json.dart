import 'dart:convert';

/// Formats [json]
String prettyJson(dynamic json) {
  var spaces = ' ' * 2;
  var encoder = JsonEncoder.withIndent(spaces);
  return encoder.convert(json);
}

/// Prints a pretty json
void printPrettyJson(dynamic json) {
  print(prettyJson(json));
}
