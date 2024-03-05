import 'package:args/command_runner.dart';

import '../api/models/json_response.dart';
import '../services/cache_service.dart';
import '../services/releases_service/releases_client.dart';
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

    final command = argResults!.rest.first;

    if (command == 'list') {
      final versions = await CacheService.fromContext.getAllVersions();

      throw ListCommandResponse(versions);
    }

    if (command == 'releases') {
      final releases = await FlutterReleases.get();

      throw ReleasesCommandResponse(releases);
    }

    return 0;
  }

  @override
  String get invocation => 'fvm api {command}';
}
