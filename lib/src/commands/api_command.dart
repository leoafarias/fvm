import 'dart:async';
import 'dart:io';

import 'package:mason_logger/mason_logger.dart';

import '../api/models/json_response.dart';
import '../utils/pretty_json.dart';
import 'base_command.dart';

class ApiCommandException implements Exception {
  final String message;

  final Object error;

  const ApiCommandException(this.message, {required this.error});
}

abstract class APISubCommand<T extends APIResponse> extends BaseFvmCommand {
  APISubCommand(super.context) {
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
    final shouldCompress = boolArg('compress');

    try {
      final response = await runSubCommand();

      if (shouldCompress) {
        print(response.toJson());
      } else {
        print(prettyJson(response.toMap()));
      }

      return ExitCode.success.code;
    } on Exception catch (e, stackTrace) {
      Error.throwWithStackTrace(
        ApiCommandException('Exception running API command $name', error: e),
        stackTrace,
      );
    }
  }
}

/// Friendly JSON API for implementations with FVM
class APICommand extends BaseFvmCommand {
  @override
  final name = 'api';

  @override
  String description = 'JSON API for FVM data';

  /// Constructor
  APICommand(super.context) {
    addSubcommand(APIListCommand(context));
    addSubcommand(APIReleasesCommand(context));
    addSubcommand(APIContextCommand(context));
    addSubcommand(APIProjectCommand(context));
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
  FutureOr<GetContextResponse> runSubCommand() {
    return services.api.getContext();
  }
}

class APIProjectCommand extends APISubCommand<GetProjectResponse> {
  @override
  final name = 'project';

  @override
  final description = 'Gets project data for FVM';

  /// Constructor
  APIProjectCommand(super.context) {
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

    return services.api.getProject(projectDir);
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
  Future<GetCacheVersionsResponse> runSubCommand() {
    final shouldSkipSizing = boolArg('skip-size-calculation');

    return services.api.getCachedVersions(
      skipCacheSizeCalculation: shouldSkipSizing,
    );
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
  Future<GetReleasesResponse> runSubCommand() {
    final limitArg = intArg('limit');
    final channelArg = stringArg('filter-channel');

    return services.api.getReleases(
      limit: limitArg,
      channelName: channelArg,
    );
  }
}
