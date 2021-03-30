import 'dart:convert';

String prettyJson(dynamic json, {int indent = 2}) {
  var spaces = ' ' * indent;
  var encoder = JsonEncoder.withIndent(spaces);
  return encoder.convert(json);
}

void printPrettyJson(dynamic json, {int indent = 2}) {
  print(prettyJson(json, indent: indent));
}
