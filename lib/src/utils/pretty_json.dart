import 'dart:convert';

/// Formats [json]
String prettyJson(dynamic json) {
  var spaces = ' ' * 2;
  var encoder = JsonEncoder.withIndent(spaces);
  return encoder.convert(json);
}

String mapToYaml(Map<String, dynamic> map, [int indentLevel = 0]) {
  final buffer = StringBuffer();

  map.forEach((key, value) {
    final indent = ' ' * indentLevel * 2;
    buffer.write('$indent$key:');

    if (value is Map<String, dynamic>) {
      buffer.write('\n');
      buffer.write(mapToYaml(value, indentLevel + 1));
    } else if (value is List) {
      buffer.write('\n');
      for (var item in value) {
        buffer.write('$indent  - ');
        if (item is Map<String, dynamic>) {
          buffer.write('\n');
          buffer.write(mapToYaml(item, indentLevel + 2));
        } else {
          buffer.write('$item\n');
        }
      }
    } else if (value == null) {
      buffer.write(' null\n');
    } else if (value is bool) {
      buffer.write(value ? ' true\n' : ' false\n');
    } else {
      buffer.write(' $value\n');
    }
  });

  return buffer.toString();
}
