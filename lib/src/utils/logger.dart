import 'dart:async';

import 'package:dart_console/dart_console.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:interact/interact.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:tint/tint.dart';

/// Sets default logger mode
FvmLogger get logger => ctx.get<FvmLogger>();

class FvmLogger extends Logger {
  /// Constructor
  FvmLogger({
    super.level,
  });
  void get divider {
    info(
      '------------------------------------------------------------',
    );
  }

  void get spacer {
    info('');
  }

  bool get isVerbose => logger.level == Level.verbose;

  void complete(String message) {
    info('${Icons.success.green()} $message');
  }

  void fail(String message) {
    info('${Icons.failure.red()} $message');
  }

  @override
  bool confirm(String? message, {bool? defaultValue}) {
    // When running tests, always return true.
    if (ctx.isTest) return true;

    return Confirm(prompt: message ?? '', defaultValue: defaultValue)
        .interact();
  }

  String select(
    String? message, {
    required List<String> options,
  }) {
    final selection = Select(
      prompt: message ?? '',
      options: options,
    ).interact();

    return options[selection];
  }

  void notice(String message) {
    // Add 2 due to the warning icon.

    final label = '${Icons.warning} $message'.yellow();

    final table = Table()
      ..insertRow([label])
      ..borderColor = ConsoleColor.yellow
      ..borderType = BorderType.outline
      ..borderStyle = BorderStyle.square;

    // print(yellow.wrap(border));
    // info('$pipe $warningIcon $message $pipe');
    // print(yellow.wrap(border));
    logger.write(table.toString());
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

class Icons {
  const Icons._();
  // Success: ✓
  static String get success => '✓';

  // Failure: ✗
  static String get failure => '✗';

  // Information: ℹ
  static String get info => 'ℹ';

  // Warning: ⚠
  static String get warning => '⚠';

  // Arrow Right: →
  static String get arrowRight => '→';

  // Arrow Left: ←
  static String get arrowLeft => '←';

  // Check Box: ☑
  static String get checkBox => '☑';

  // Star: ★
  static String get star => '★';

  // Circle: ●
  static String get circle => '●';

  // Square: ■
  static String get square => '■';
}
