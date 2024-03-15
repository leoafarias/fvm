import 'package:args/command_runner.dart';

/// Base Command
abstract class BaseCommand extends Command<int> {
  BaseCommand();

  @override
  String get invocation => 'fvm $name';
}

extension CommandExtension on Command {
  /// Checks if the command-line option named [name] was parsed.
  bool wasParsed(String name) => argResults!.wasParsed(name);

  /// Gets the parsed command-line option named [name] as `bool`.
  bool boolArg(String name) => argResults![name] == true;

  /// Gets the parsed command-line option named [name] as `String`.
  String? stringArg(String name) {
    final arg = argResults![name] as String?;
    if (arg == 'null' || (arg == null || arg.isEmpty)) {
      return null;
    }

    return arg;
  }

  int? intArg(String name) {
    final arg = stringArg(name);

    return arg == null ? null : int.tryParse(arg);
  }

  /// Gets the parsed command-line option named [name] as `List<String>`.
  // ignore: prefer-correct-json-casts
  List<String?> stringsArg(String name) => argResults![name] as List<String>;
}
