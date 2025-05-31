import 'package:dart_console/dart_console.dart';

Table createTable([List<String> columns = const []]) {
  final table = Table()
    ..borderColor = ConsoleColor.white
    ..borderType = BorderType.grid
    ..borderStyle = BorderStyle.square
    ..headerStyle = FontStyle.bold;

  for (final column in columns) {
    table.insertColumn(header: column, alignment: TextAlignment.left);
  }

  return table;
}
