import 'package:args/command_runner.dart';
import 'package:meta/meta.dart';

import '../services/base_service.dart';
import '../services/logger_service.dart';
import '../utils/context.dart';

/// Base Command
abstract class BaseFvmCommand extends Command<int> {
  @protected
  final FvmContext context;

  BaseFvmCommand(this.context);

  Logger get logger => context.get();

  T get<T extends Contextual>() => context.get();

  @override
  String get invocation => 'fvm $name';

  // Override to make sure commands are visible by default
  @override
  bool get hidden => false;
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
