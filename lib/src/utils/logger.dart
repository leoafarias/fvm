import 'dart:async';

import 'package:mason_logger/mason_logger.dart';

/// Sets default logger mode
final logger = Logger();

extension LoggerExtension on Logger {
  void get divider {
    info(
      '------------------------------------------------------------',
    );
  }

  void get spacer {
    info('');
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
