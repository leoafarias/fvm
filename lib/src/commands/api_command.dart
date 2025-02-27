import 'dart:async';
import 'dart:io';

import 'package:mason_logger/mason_logger.dart';

import '../api/models/json_response.dart';
import '../utils/pretty_json.dart';
import 'base_command.dart';

abstract class APISubCommand<T extends APIResponse> extends BaseCommand {
  APISubCommand(super.controller) {
    argParser.addFlag(
      'compress',
      abbr: 'c',
      help: 'Prints JSON with no whitespace',
      negatable: false,
    );
  }

  FutureOr<T> runSubCommand();

  @override
  Future<int> run() async {
    try {
      final shouldCompress = boolArg('compress');

      final response = await runSubCommand();

      if (shouldCompress) {
        print(response.toJson());
      } else {
        print(prettyJson(response.toMap()));
      }

      exit(ExitCode.success.code);
    } on Exception catch (_) {
      rethrow;
    }
  }
}

/// Friendly JSON API for implementations with FVM
class APICommand extends BaseCommand {
  @override
  final name = 'api';

  @override
  String description = 'JSON API for FVM data';

  /// Constructor
  APICommand(super.controller) {
    addSubcommand(APIListCommand(controller));
    addSubcommand(APIReleasesCommand(controller));
    addSubcommand(APIContextCommand(controller));
    addSubcommand(APIProjectCommand(controller));
  }

  @override
  String get invocation => 'fvm api [command]';
}

class APIContextCommand extends APISubCommand<GetContextResponse> {
  @override
  final name = 'context';

  @override
  final description = 'Gets context data for FVM';

  /// Constructor
  APIContextCommand(super.controller);

  @override
  FutureOr<GetContextResponse> runSubCommand() async {
    return controller.api.getContext();
  }
}

class APIProjectCommand extends APISubCommand<GetProjectResponse> {
  @override
  final name = 'project';

  @override
  final description = 'Gets project data for FVM';

  /// Constructor
  APIProjectCommand(super.controller) {
    argParser.addOption(
      'path',
      abbr: 'p',
      help: 'Path to project, defaults to working directory if not provided',
    );
  }

  @override
  FutureOr<GetProjectResponse> runSubCommand() async {
    final projectPath = stringArg('path');

    Directory? projectDir;

    if (projectPath != null) {
      projectDir = Directory(projectPath);
    }

    return controller.api.getProject(projectDir);
  }
}

class APIListCommand extends APISubCommand<GetCacheVersionsResponse> {
  @override
  final name = 'list';

  @override
  final description = 'Lists installed Flutter SDK Versions';

  /// Constructor
  APIListCommand(super.controller) {
    argParser.addFlag(
      'skip-size-calculation',
      abbr: 's',
      help:
          'Skips calculating the size of the versions, useful for large caches',
      negatable: false,
    );
  }

  @override
  Future<GetCacheVersionsResponse> runSubCommand() async {
    final shouldSkipSizing = boolArg('skip-size-calculation');

    return await controller.api
        .getCachedVersions(skipCacheSizeCalculation: shouldSkipSizing);
  }
}

class APIReleasesCommand extends APISubCommand<GetReleasesResponse> {
  @override
  final name = 'releases';

  @override
  final description = 'Lists Flutter SDK Releases';

  /// Constructor
  APIReleasesCommand(super.controller) {
    argParser
      ..addOption(
        'limit',
        help: 'Limits the amount of releases',
        valueHelp: 'limit',
      )
      ..addOption(
        'filter-channel',
        help: 'Filter by channel name',
        allowed: ['stable', 'beta', 'dev'],
      );
  }

  @override
  Future<GetReleasesResponse> runSubCommand() async {
    final limitArg = intArg('limit');
    final channelArg = stringArg('filter-channel');

    return await controller.api
        .getReleases(limit: limitArg, channelName: channelArg);
  }
}
