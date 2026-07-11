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

  /// Gets the parsed command-line option named [name] as a positive `int`.
  int? positiveIntArg(String name) {
    final arg = argResults![name] as String?;
    if (arg == null) return null;

    final value = int.tryParse(arg);
    if (value == null || value < 1) {
      throw UsageException(
        'Option --$name must be a positive integer.',
        usage,
      );
    }

    return value;
  }

  /// Gets the parsed command-line option named [name] as `List<String>`.
  List<String?> stringsArg(String name) => (argResults![name] as List).cast();

  /// Gets the first rest argument if available, otherwise returns null
  String? get firstRestArg =>
      argResults!.rest.isEmpty ? null : argResults!.rest[0];
}
