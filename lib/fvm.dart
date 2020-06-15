import 'dart:io';
import 'package:fvm/commands/config.dart';
import 'package:fvm/commands/flutter.dart';
import 'package:fvm/commands/install.dart';
import 'package:fvm/commands/list.dart';
import 'package:fvm/commands/remove.dart';
import 'package:fvm/commands/runner.dart';
import 'package:fvm/commands/use.dart';
import 'package:fvm/commands/version.dart';
import 'package:fvm/utils/logger.dart';
import 'package:fvm/utils/logger.dart' show logger;
import 'package:io/ansi.dart';

/// Runs FVM
Future<void> fvmRunner(List<String> args) async {
  final runner = buildRunner();

  runner..addCommand(InstallCommand());
  runner..addCommand(ListCommand());
  runner..addCommand(FlutterCommand());
  runner..addCommand(RemoveCommand());
  runner..addCommand(UseCommand());
  runner..addCommand(ConfigCommand());
  runner..addCommand(VersionCommand());

  return await runner.run(args).catchError((exc, st) {
    if (exc is String) {
      logger.stdout(exc);
    } else {
      logger.stderr('⚠️  ${yellow.wrap(exc?.message as String)}');
      if (args.contains('--verbose')) {
        print(st);
        throw exc;
      }
    }
    exitCode = 1;
  }).whenComplete(() {});
}
