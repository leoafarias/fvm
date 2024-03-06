import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:io/io.dart';

import '../api/api_service.dart';
import '../api/models/json_response.dart';
import 'base_command.dart';

/// Friendly API for implementations with FVM
class ApiCommand extends BaseCommand {
  @override
  final name = 'api';

  @override
  String description = 'JSON API for certain commands in FVM';

  /// Constructor
  ApiCommand() {
    argParser.addFlag(
      'pretty',
      help: 'Prints JSON in pretty format',
      negatable: false,
    );
  }
  @override
  Future<int> run() async {
    if (argResults!.rest.isEmpty) {
      throw UsageException('No command was provided', usage);
    }

    final prettyOutput = boolArg('pretty');

    void printAndExitResponse<T>(APIResponse<T> response) {
      if (prettyOutput) {
        print(response.formattedJson());
      } else {
        print(response.toJson());
      }

      exit(ExitCode.success.code);
    }

    final command = argResults!.rest.first;

    switch (command) {
      case 'list':
        final response = await APIService.fromContext.getCachedVersions();

        printAndExitResponse(response);
        break;
      case 'releases':
        final response = await APIService.fromContext.getReleases();
        printAndExitResponse(response);
        break;
      case 'project':
        final response = APIService.fromContext.getProject();
        printAndExitResponse(response);
        break;
      default:
        throw UsageException('Command not found', usage);
    }

    return 0;
  }

  @override
  String get invocation => 'fvm api {command}';
}
