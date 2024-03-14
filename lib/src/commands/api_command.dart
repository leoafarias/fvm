import 'dart:async';
import 'dart:io';

import 'package:mason_logger/mason_logger.dart';

import '../api/api_service.dart';
import '../api/models/json_response.dart';
import '../utils/pretty_json.dart';
import 'base_command.dart';

abstract class APISubCommand<T extends APIResponse> extends BaseCommand {
  APISubCommand() {
    argParser.addFlag(
      'compress',
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
  APICommand() {
    addSubcommand(APIListCommand());
    addSubcommand(APIReleasesCommand());
    addSubcommand(APIContextCommand());
    addSubcommand(APIProjectCommand());
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
  APIContextCommand();

  @override
  FutureOr<GetContextResponse> runSubCommand() async {
    return APIService.fromContext.getContext();
  }
}

class APIProjectCommand extends APISubCommand<GetProjectResponse> {
  @override
  final name = 'project';

  @override
  final description = 'Gets project data for FVM';

  /// Constructor
  APIProjectCommand() {
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

    return APIService.fromContext.getProject(projectDir);
  }
}

class APIListCommand extends APISubCommand<GetCacheVersionsResponse> {
  @override
  final name = 'list';

  @override
  final description = 'Lists installed Flutter SDK Versions';

  /// Constructor
  APIListCommand() {
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

    return await APIService.fromContext
        .getCachedVersions(skipCacheSizeCalculation: shouldSkipSizing);
  }
}

class APIReleasesCommand extends APISubCommand<GetReleasesResponse> {
  @override
  final name = 'releases';

  @override
  final description = 'Lists Flutter SDK Releases';

  /// Constructor
  APIReleasesCommand() {
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

    return await APIService.fromContext
        .getReleases(limit: limitArg, channelName: channelArg);
  }
}
