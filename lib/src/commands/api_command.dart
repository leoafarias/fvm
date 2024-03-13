import 'dart:convert';
import 'dart:io';

import 'package:io/io.dart';

import '../api/api_service.dart';
import '../api/models/json_response.dart';
import '../utils/pretty_json.dart';
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
    addSubcommand(APIInfoCommand());
    addSubcommand(APIQueryCommand());
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

void _printAndExitResponse(APIResponse response, {bool compress = false}) {
  if (compress) {
    print(response.toJson());
  } else {
    print(response.toPrettyJson());
  }

  exit(ExitCode.success.code);
}

class APIQueryCommand extends BaseCommand {
  @override
  final name = 'query';

  @override
  final description =
      'Query the API with dot notation. Example: fvm api query project.flavors.production';

  /// Constructor
  APIQueryCommand() {
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

    // Get arguments that were passed

    if (argResults!.rest.isEmpty) {
      _printAndExitResponse(response, compress: compressArg);

      return 0;
    }

    final args = argResults!.rest.first.split('.');
    final payload = jsonDecode(response.toJson());
    final result = navigateJson(payload, args);

    print(prettyJson(result));
    exit(ExitCode.success.code);
  }
}

// ignore: avoid-dynamic
dynamic navigateJson(dynamic currentPart, List<String> path) {
  if (path.isEmpty || currentPart == null) return currentPart;
  String currentKey = path.first;
  if (currentPart[currentKey] is String) {
    return {currentKey: currentPart[currentKey]};
  }
  if (currentPart is Map<String, dynamic> &&
      currentPart.containsKey(currentKey)) {
    return navigateJson(currentPart[currentKey], path.sublist(1));
  }

  return currentPart[currentKey];
}
