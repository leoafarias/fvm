import 'dart:async';

import 'package:fvm/src/services/context.dart';
import 'package:mason_logger/mason_logger.dart';

/// Sets default logger mode
final logger = FvmLogger();

class FvmLogger extends Logger {
  void get divider {
    info(
      '------------------------------------------------------------',
    );
  }

  void get spacer {
    info('');
  }

  void complete(String message) {
    // \u2714
    // info('✅ $message');
    info('${green.wrap('\u2714')} $message');
  }

  @override
  bool confirm(String? message, {bool defaultValue = false}) {
    // When running tests, always return true.
    if (ctx.isTest) return true;
    return super.confirm(
      message,
      defaultValue: defaultValue,
    );
  }

  void notice(String message) {
    // Add 2 due to the warning icon.
    final border = '-${'-' * (message.length + 2 + 2)}-';
    final pipe = yellow.wrap('|');
    final warningIcon = yellow.wrap('⚠');

    print(yellow.wrap(border));
    info('$pipe $warningIcon $message $pipe');
    print(yellow.wrap(border));
  }
}

/// Logger for FVM
/// Console controller instance
final consoleController = ConsoleController();

/// Console Controller
class ConsoleController {
  /// stdout stream
  final stdout = StreamController<List<int>>();

  /// sderr stream
  final stderr = StreamController<List<int>>();

  /// warning stream
  final warning = StreamController<List<int>>();

  /// fine stream
  final fine = StreamController<List<int>>();

  /// info streamm
  final info = StreamController<List<int>>();

  /// error stream
  final error = StreamController<List<int>>();
}
