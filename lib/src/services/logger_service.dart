import 'dart:async';

import 'package:dart_console/dart_console.dart';
import 'package:fvm/src/services/base_service.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:interact/interact.dart' as interact;
import 'package:mason_logger/mason_logger.dart';
import 'package:tint/tint.dart';

/// Sets default logger mode
LoggerService get logger => getProvider();

class LoggerService extends ContextService {
  final Logger _logger;

  /// Constructor
  LoggerService({Level? level, FVMContext? context})
      : _logger = Logger(level: level ?? Level.info),
        super(context);

  void get spacer => _logger.info('');

  bool get isVerbose => _logger.level == Level.verbose;

  Level get level => _logger.level;

  String get stdout {
    return logger.stdout;
  }

  void get divider {
    _logger.info(
      '------------------------------------------------------------',
    );
  }

  set level(Level level) => _logger.level = level;

  void success(String message) {
    _logger.info('${Icons.success.green()} $message');
  }

  void fail(String message) {
    _logger.info('${Icons.failure.red()} $message');
  }

  void warn(String message) => _logger.warn(message);
  void info(String message) => _logger.info(message);
  void err(String message) => _logger.err(message);
  void detail(String message) => _logger.detail(message);

  void write(String message) => _logger.write(message);
  Progress progress(String message) {
    final progress = _logger.progress(message);
    if (isVerbose) {
      // if verbose then cancel for other data been displayed and overlapping
      progress.cancel();
      // Replace for a normal log
      logger.info(message);
    }
    return progress;
  }

  bool confirm(String? message, {bool? defaultValue}) {
    // When running tests, always return true.
    if (context.isTest) return true;

    return interact.Confirm(prompt: message ?? '', defaultValue: defaultValue)
        .interact();
  }

  String select(String? message, {required List<String> options}) {
    final selection = interact.Select(
      prompt: message ?? '',
      options: options,
      initialIndex: 0,
    ).interact();

    return options[selection];
  }

  void notice(String message) {
    // Add 2 due to the warning icon.

    final label = '${Icons.warning} $message'.brightYellow();

    final table = Table()
      ..insertRow([label])
      ..borderColor = ConsoleColor.yellow
      ..borderType = BorderType.outline
      ..borderStyle = BorderStyle.square;

    _logger.write(table.toString());
  }

  void important(String message) {
    // Add 2 due to the warning icon.

    final label = '${Icons.success} $message'.cyan();

    final table = Table()
      ..insertRow([label])
      ..borderColor = ConsoleColor.cyan
      ..borderType = BorderType.outline
      ..borderStyle = BorderStyle.square;

    _logger.write(table.toString());
  }
}

final dot = '\u{25CF}'; // ●
final rightArrow = '\u{2192}'; // →

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
