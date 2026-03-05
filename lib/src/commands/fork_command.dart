import 'package:args/command_runner.dart';
import 'package:io/io.dart';

import '../models/config_model.dart';
import '../models/flutter_version_model.dart';
import '../utils/helpers.dart';
import 'base_command.dart';

/// Command to manage Flutter forks.
///
/// Allows users to define and use custom Flutter repositories.
/// Forks are defined by an alias and a Git URL, and can be used
/// with the syntax `alias/version`.
///
/// Examples:
/// - `fvm fork add mycompany https://github.com/mycompany/flutter.git`
/// - `fvm install mycompany/stable`
/// - `fvm use mycompany/2.10.0`
class ForkCommand extends BaseFvmCommand {
  @override
  final name = 'fork';
  @override
  final description = 'Manage Flutter fork aliases';
  @override
  final hidden = false; // Explicitly set to false to ensure visibility

  ForkCommand(super.context) {
    addSubcommand(ForkAddCommand(context));
    addSubcommand(ForkRemoveCommand(context));
    addSubcommand(ForkListCommand(context));
  }
}

/// Adds a new Flutter fork alias.
///
/// The alias can then be used with any FVM command that accepts a version,
/// using the format `alias/version`.
class ForkAddCommand extends BaseFvmCommand {
  @override
  final name = 'add';
  @override
  final description = 'Adds a new Flutter fork alias for custom repositories';
  @override
  final hidden = false;

  ForkAddCommand(super.context);

  @override
  Future<int> run() async {
    final args = argResults!.rest;
    if (args.length < 2) {
      throw UsageException('Usage: fvm fork add <alias> <url>', usage);
    }
    final alias = args[0];
    final url = args[1];

    // Validate alias format
    final aliasPattern = RegExp(r'^[A-Za-z0-9._-]+$');
    if (!aliasPattern.hasMatch(alias)) {
      throw UsageException(
        'Invalid fork alias format: "$alias"\n'
        'Alias must contain only letters, numbers, dots, hyphens, '
        'and underscores.',
        usage,
      );
    }

    // Validate URL format
    if (!isValidGitUrl(url)) {
      throw UsageException(
        'Invalid Git URL format: $url\n'
        'URL must be a valid Git repository URL '
        '(e.g., https://github.com/user/repo.git)',
        usage,
      );
    }

    // Check for duplicate alias
    final config = LocalAppConfig.read();
    if (config.forks.any((f) => f.name == alias)) {
      throw UsageException(
        'Fork alias "$alias" already exists. Remove it first if you want to update.',
        usage,
      );
    }

    final forkDef = FlutterFork(name: alias, url: url);

    config
      ..forks.add(forkDef)
      ..save();

    logger.info('Fork alias "$alias" added pointing to $url');
    logger.info('You can now use it with: fvm install $alias/stable');

    return ExitCode.success.code;
  }
}

/// Removes a Flutter fork alias.
class ForkRemoveCommand extends BaseFvmCommand {
  @override
  final name = 'remove';
  @override
  final description = 'Removes a configured Flutter fork alias';
  @override
  final hidden = false;

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

    logger.info('Fork alias "$alias" removed');

    return ExitCode.success.code;
  }
}

/// Lists all configured Flutter fork aliases.
class ForkListCommand extends BaseFvmCommand {
  @override
  final name = 'list';
  @override
  final description = 'Lists all configured Flutter fork aliases';
  @override
  final hidden = false;

  ForkListCommand(super.context);

  @override
  Future<int> run() async {
    final forks = LocalAppConfig.read().forks;
    if (forks.isEmpty) {
      logger.info('No fork aliases found');
      logger.info('To add a fork, use: fvm fork add <alias> <url>');
    } else {
      logger.info('Configured fork aliases:');
      for (final fork in forks) {
        final alias = fork.name;
        final url = fork.url;
        logger.info('$alias: $url');
      }
      logger.info('\nUse with: fvm install <alias>/<version>');
    }

    return ExitCode.success.code;
  }
}
