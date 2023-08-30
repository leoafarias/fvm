import 'package:args/command_runner.dart';

/// Base Command
abstract class BaseCommand extends Command<int> {
  BaseCommand();

  @override
  String get invocation => 'fvm $name';

  /// Gets the parsed command-line option named [name] as `bool`.
  bool boolArg(String name) => argResults![name] == true;

  /// Gets the parsed command-line option named [name] as `String`.
  String? stringArg(String name) => argResults![name] as String?;

  /// Gets the parsed command-line option named [name] as `List<String>`.
  List<String?> stringsArg(String name) => argResults![name] as List<String>;
}
