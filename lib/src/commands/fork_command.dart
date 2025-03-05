import 'package:args/command_runner.dart';
import 'package:io/io.dart';

import '../models/config_model.dart';
import '../models/flutter_version_model.dart';
import 'base_command.dart';

class ForkCommand extends BaseFvmCommand {
  @override
  final name = 'fork';
  @override
  final description = 'Manage Flutter fork aliases';

  ForkCommand(super.context) {
    addSubcommand(ForkAddCommand(context));
    addSubcommand(ForkRemoveCommand(context));
    addSubcommand(ForkListCommand(context));
  }
}

class ForkAddCommand extends BaseFvmCommand {
  @override
  final name = 'add';
  @override
  final description = 'Adds a new fork. Usage: fvm fork add <alias> <url>';

  ForkAddCommand(super.context);

  @override
  Future<int> run() async {
    final args = argResults!.rest;
    if (args.length < 2) {
      throw UsageException('Usage: fvm fork add <alias> <url>', usage);
    }
    final alias = args[0];
    final url = args[1];

    final forkDef = FlutterFork(name: alias, url: url);

    LocalAppConfig.read()
      ..forks.add(forkDef)
      ..save();

    logger.success('Fork alias "$alias" added pointing to $url');

    return ExitCode.success.code;
  }
}

class ForkRemoveCommand extends BaseFvmCommand {
  @override
  final name = 'remove';
  @override
  final description = 'Removes a fork alias. Usage: fvm fork remove <alias>';

  ForkRemoveCommand(super.context);

  @override
  Future<int> run() async {
    final args = argResults!.rest;
    if (args.isEmpty) {
      // Show usage error
      throw UsageException('Usage: fvm fork remove <alias>', usage);
    }
    final alias = args[0];

    LocalAppConfig.read()
      ..forks.removeWhere((f) => f.name == alias)
      ..save();

    logger.success('Fork alias "$alias" removed');

    return ExitCode.success.code;
  }
}

class ForkListCommand extends BaseFvmCommand {
  @override
  final name = 'list';
  @override
  final description = 'Lists all fork aliases. Usage: fvm fork list';

  ForkListCommand(super.context);

  @override
  Future<int> run() async {
    final forks = LocalAppConfig.read().forks;
    if (forks.isEmpty) {
      logger.info('No fork aliases found');
    } else {
      for (final fork in forks) {
        final alias = fork.name;
        final url = fork.url;
        logger.info('$alias: $url');
      }
    }

    return ExitCode.success.code;
  }
}
