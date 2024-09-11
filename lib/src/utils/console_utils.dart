import 'package:dart_console/dart_console.dart';

import '../models/cache_flutter_version_model.dart';
import '../services/logger_service.dart';
import 'exceptions.dart';

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

/// Allows to select from cached sdks.
String cacheVersionSelector(List<CacheFlutterVersion> versions) {
  // Return message if no cached versions
  if (versions.isEmpty) {
    throw const AppException(
      'No versions installed. Please install'
      ' a version. "fvm install {version}". ',
    );
  }

  /// Ask which version to select

  final versionsList = versions.map((version) => version.name).toList();

  final choice = logger.select('Select a version: ', options: versionsList);

  return choice;
}
