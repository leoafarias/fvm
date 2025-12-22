import 'dart:async';
import 'dart:io';

import 'package:io/io.dart';
import 'package:mason_logger/mason_logger.dart';

import '../api/api_service.dart';
import '../api/models/json_response.dart';
import '../utils/exceptions.dart';
import '../utils/pretty_json.dart';
import 'base_command.dart';

abstract class APISubCommand<T extends APIResponse> extends BaseFvmCommand {
  APISubCommand(super.context) {
    argParser.addFlag(
      'compress',
      abbr: 'c',
      help: 'Outputs compact JSON without formatting or whitespace',
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
        AppDetailedException(
          'Exception running API command $name',
          e.toString(),
        ),
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
  String description =
      'Provides JSON API access to FVM data for integrations and tooling';

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
  final description =
      'Returns FVM environment and configuration information as JSON';

  APIContextCommand(super.controller);

  @override
  FutureOr<GetContextResponse> runSubCommand() {
    return get<ApiService>().getContext();
  }
}

class APIProjectCommand extends APISubCommand<GetProjectResponse> {
  @override
  final name = 'project';

  @override
  final description =
      'Returns Flutter project configuration and settings as JSON';

  APIProjectCommand(super.context) {
    argParser.addOption(
      'path',
      abbr: 'p',
      help: 'Path to Flutter project (defaults to current directory)',
    );
  }

  @override
  FutureOr<GetProjectResponse> runSubCommand() async {
    final projectPath = stringArg('path');

    Directory? projectDir;

    if (projectPath != null) {
      projectDir = Directory(projectPath);
    }

    return get<ApiService>().getProject(projectDir);
  }
}

class APIListCommand extends APISubCommand<GetCacheVersionsResponse> {
  @override
  final name = 'list';

  @override
  final description = 'Returns installed Flutter SDK versions as JSON';

  APIListCommand(super.controller) {
    argParser.addFlag(
      'skip-size-calculation',
      abbr: 's',
      help:
          'Skips calculating cache sizes for faster response (useful for large caches)',
      negatable: false,
    );
  }

  @override
  Future<GetCacheVersionsResponse> runSubCommand() {
    final shouldSkipSizing = boolArg('skip-size-calculation');

    return get<ApiService>().getCachedVersions(
      skipCacheSizeCalculation: shouldSkipSizing,
    );
  }
}

class APIReleasesCommand extends APISubCommand<GetReleasesResponse> {
  @override
  final name = 'releases';

  @override
  final description = 'Returns available Flutter SDK releases as JSON';

  APIReleasesCommand(super.controller) {
    argParser
      ..addOption(
        'limit',
        help: 'Limits the number of releases returned',
        valueHelp: 'number',
      )
      ..addOption(
        'filter-channel',
        help: 'Filters releases by channel (stable, beta, dev)',
        allowed: ['stable', 'beta', 'dev'],
      );
  }

  @override
  Future<GetReleasesResponse> runSubCommand() {
    final limitArg = intArg('limit');
    final channelArg = stringArg('filter-channel');

    return get<ApiService>().getReleases(
      limit: limitArg,
      channelName: channelArg,
    );
  }
}
