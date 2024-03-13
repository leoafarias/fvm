import 'dart:io';

import 'package:io/io.dart';

import '../api/api_service.dart';
import '../api/models/json_response.dart';
import 'base_command.dart';

/// Friendly API for implementations with FVM
class ApiCommand extends BaseCommand {
  @override
  final name = 'api';

  @override
  String description = 'JSON API for FVM data';

  /// Constructor
  ApiCommand() {
    addSubcommand(APIListCommand());
    addSubcommand(APIReleasesCommand());
    addSubcommand(APIProjectCommand());
    addSubcommand(APIInfoCommand());
  }

  @override
  String get invocation => 'fvm api {command}';
}

class APIInfoCommand extends BaseCommand {
  @override
  final name = 'info';

  @override
  final description = 'Gets info for FVM';

  /// Constructor
  APIInfoCommand() {
    argParser.addFlag(
      'compress',
      help: 'Prints JSON with no whitespace',
      negatable: false,
    );
  }

  @override
  Future<int> run() async {
    final compressArg = boolArg('compress');
    final response = APIService.fromContext.getInfo();

    _printAndExitResponse(response, compress: compressArg);

    return 0;
  }
}

class APIListCommand extends BaseCommand {
  @override
  final name = 'list';

  @override
  final description = 'Lists installed Flutter SDK Versions';

  /// Constructor
  APIListCommand() {
    argParser
      ..addFlag(
        'compress',
        abbr: 'c',
        help: 'Prints JSON with no whitespace',
        negatable: false,
      )
      ..addFlag(
        'skip-size-calculation',
        abbr: 's',
        help:
            'Skips calculating the size of the versions, useful for large caches',
        negatable: false,
      );
  }

  @override
  Future<int> run() async {
    final compressArg = boolArg('compress');
    final skipSizeArg = boolArg('skip-size-calculation');

    final response = await APIService.fromContext
        .getCachedVersions(skipCacheSizeCalculation: skipSizeArg);

    _printAndExitResponse(response, compress: compressArg);

    return 0;
  }
}

class APIReleasesCommand extends BaseCommand {
  @override
  final name = 'releases';

  @override
  final description = 'Lists Flutter SDK Releases';

  /// Constructor
  APIReleasesCommand() {
    argParser
      ..addFlag(
        'compress',
        help: 'Prints JSON with no whitespace',
        negatable: false,
      )
      ..addOption(
        'limit',
        help: 'Limits the amount of releases',
        valueHelp: 'limit',
        defaultsTo: '30',
      );
  }

  @override
  Future<int> run() async {
    final limitArg = int.tryParse(argResults!['limit'])!;

    final compressArg = boolArg('compress');
    final response = await APIService.fromContext.getReleases(limit: limitArg);

    _printAndExitResponse(response, compress: compressArg);

    return 0;
  }
}

class APIProjectCommand extends BaseCommand {
  @override
  final name = 'project';

  @override
  final description = 'Gets the current project';

  /// Constructor
  APIProjectCommand() {
    argParser.addFlag(
      'compress',
      help: 'Prints JSON with no whitespace',
      negatable: false,
    );
  }

  @override
  Future<int> run() async {
    final compressArg = boolArg('compress');
    final response = APIService.fromContext.getProject();

    _printAndExitResponse(response, compress: compressArg);

    return 0;
  }
}

void _printAndExitResponse(APIResponse response, {bool compress = false}) {
  if (compress) {
    print(response.toJson());
  } else {
    print(response.toPrettyJson());
  }

  exit(ExitCode.success.code);
}
