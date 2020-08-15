import 'package:console/console.dart';

/// Displays notice for confirmation
Future<bool> confirm(String message) async {
  final response = await readInput('$message Y/n: ');
  // Return true unless 'n'
  return !response.contains('n');
}
