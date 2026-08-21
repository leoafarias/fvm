import 'package:dart_console/dart_console.dart';
import 'package:io/io.dart';

import '../models/project_registry_model.dart';
import '../services/logger_service.dart';
import '../services/project_registry_service.dart';
import '../utils/context.dart';
import 'base_command.dart';

/// Manages the cache-local FVM project registry.
class ProjectsCommand extends BaseFvmCommand {
  @override
  final name = 'projects';

  @override
  final description =
      'Lists and manages projects recorded for the active FVM cache';

  ProjectsCommand(super.context) {
    addSubcommand(ProjectsListCommand(context));
    addSubcommand(ProjectsAddCommand(context));
    addSubcommand(ProjectsRemoveCommand(context));
    addSubcommand(ProjectsPruneCommand(context));
  }

  @override
  Future<int> run() => _printProjectsList(context: context, logger: logger);
}

class ProjectsListCommand extends BaseFvmCommand {
  @override
  final name = 'list';

  @override
  final description = 'Lists projects recorded for the active FVM cache';

  ProjectsListCommand(super.context);

  @override
  Future<int> run() => _printProjectsList(context: context, logger: logger);
}

class ProjectsAddCommand extends BaseFvmCommand {
  @override
  final name = 'add';

  @override
  final description =
      'Adds or refreshes the nearest configured FVM project in the registry';

  ProjectsAddCommand(super.context);

  @override
  Future<int> run() async {
    final path = firstRestArg;
    final project = await get<ProjectRegistryService>().addFromPath(path);
    logger.success('Registered ${project.name} at ${project.path}');

    return ExitCode.success.code;
  }
}

class ProjectsRemoveCommand extends BaseFvmCommand {
  @override
  final name = 'remove';

  @override
  final description =
      'Removes a project from the registry without changing the project or cache';

  ProjectsRemoveCommand(super.context);

  @override
  Future<int> run() async {
    final path = firstRestArg;
    if (path == null) {
      logger.fail('Please provide a project path to remove from the registry.');

      return ExitCode.usage.code;
    }

    final removed = await get<ProjectRegistryService>().removePath(path);
    if (removed) {
      logger.success('Removed registry entry for $path');
    } else {
      logger.info('Project is not registered: $path');
    }

    return ExitCode.success.code;
  }
}

class ProjectsPruneCommand extends BaseFvmCommand {
  @override
  final name = 'prune';

  @override
  final description =
      'Removes missing and unconfigured project entries from the registry';

  ProjectsPruneCommand(super.context) {
    argParser.addFlag(
      'force',
      abbr: 'f',
      help: 'Skip the confirmation prompt',
      negatable: false,
    );
  }

  @override
  Future<int> run() async {
    final force = boolArg('force');
    final service = get<ProjectRegistryService>();
    final stale = [
      for (final project in await service.listProjects())
        if (project.status == ProjectRegistryStatus.missing ||
            project.status == ProjectRegistryStatus.unconfigured)
          project,
    ];

    if (stale.isEmpty) {
      logger.info('No missing or unconfigured registry entries to prune.');

      return ExitCode.success.code;
    }

    logger.info('The following registry entries will be removed:');
    for (final project in stale) {
      logger.info('  ${project.path} (${project.status.name})');
    }

    final shouldProceed = force ||
        logger.confirm(
          'Remove these registry entries? Project files and cached SDKs will not be deleted.',
          defaultValue: false,
        );
    if (!shouldProceed) {
      logger.info('No registry entries were removed.');

      return ExitCode.success.code;
    }

    final removed = await service.pruneStaleEntries();
    logger.success('Removed $removed registry entries.');

    return ExitCode.success.code;
  }
}

Future<int> _printProjectsList({
  required FvmContext context,
  required Logger logger,
}) async {
  final service = context.get<ProjectRegistryService>();
  final projects = await service.listProjects();
  if (projects.isEmpty) {
    logger
      ..info('No projects are registered in ${service.registryPath}.')
      ..info(
        'Projects are recorded by fvm use, project-aware fvm install, '
        'or fvm projects add.',
      );

    return ExitCode.success.code;
  }

  final table = Table()
    ..insertColumn(header: 'Project', alignment: TextAlignment.left)
    ..insertColumn(header: 'Flutter', alignment: TextAlignment.left)
    ..insertColumn(header: 'Additional versions', alignment: TextAlignment.left)
    ..insertColumn(header: 'Status', alignment: TextAlignment.left)
    ..insertColumn(header: 'Last seen', alignment: TextAlignment.left)
    ..insertColumn(header: 'Path', alignment: TextAlignment.left)
    ..borderStyle = BorderStyle.square
    ..borderColor = ConsoleColor.white
    ..borderType = BorderType.grid
    ..headerStyle = FontStyle.bold;

  for (final project in projects) {
    final additional = _additionalVersions(project);
    final flutter = project.usesLastKnownSnapshot
        ? '${project.flutter ?? '-'} (last known)'
        : (project.flutter ?? '-');
    table.insertRows([
      [
        project.name,
        flutter,
        additional,
        project.status.name,
        project.lastSeenAt.toUtc().toIso8601String(),
        project.path,
      ],
    ]);
  }

  logger.info(table.toString());

  return ExitCode.success.code;
}

String _additionalVersions(RegisteredProject project) {
  final primary = project.flutter;
  final versions = <String>{};
  for (final value in project.flavors.values) {
    if (value != primary) {
      versions.add(value);
    }
  }
  final sorted = versions.toList()..sort();

  return sorted.join(', ');
}
