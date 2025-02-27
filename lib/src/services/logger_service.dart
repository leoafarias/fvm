import 'dart:async';
import 'dart:io';

import 'package:dart_console/dart_console.dart';
import 'package:interact/interact.dart' as interact;
import 'package:mason_logger/mason_logger.dart' as mason;
import 'package:stack_trace/stack_trace.dart';
import 'package:tint/tint.dart';

import '../models/cache_flutter_version_model.dart';
import '../utils/exceptions.dart';
import '../utils/extensions.dart';

// LoggerService get logger => ctx.loggerService;

enum Level {
  /// The most verbose log level -- everything is logged.
  verbose,

  /// Used for debug info.
  debug,

  /// Default log level used for standard logs.
  info,

  /// Used to indicate a potential problem.
  warning,

  /// Used to indicate a problem.
  error,

  /// Used to indicate an urgent/severe problem.
  critical,

  /// The least verbose level -- nothing is logged.
  quiet;
}

mason.Level _toMasonLevel(Level level) {
  return mason.Level.values.firstWhere((e) => e.name == level.name);
}

class Logger {
  final mason.Logger _logger;
  final bool _isTest;
  final bool _isCI;
  final bool _skipInput;

  /// Constructor
  Logger({
    required Level logLevel,
    required bool isTest,
    required bool isCI,
    required bool skipInput,
  })  : _logger = mason.Logger(level: _toMasonLevel(logLevel)),
        _isTest = isTest,
        _isCI = isCI,
        _skipInput = skipInput;

  void _printProgressBar(String label, int percentage) {
    final progressBarWidth = 50;
    final progressInBlocks = (percentage / 100 * progressBarWidth).round();
    final progressBlocks = '${mason.green.wrap('█')}' * progressInBlocks;
    final remainingBlocks = '.' * (progressBarWidth - progressInBlocks);

    final output = '\r $label [$progressBlocks$remainingBlocks] $percentage%';

    write(output);
  }

  void get spacer => _logger.info('');

  bool get isVerbose => _logger.level == mason.Level.verbose;

  mason.Level get level => _logger.level;

  void get divider {
    _logger.info(
      '------------------------------------------------------------',
    );
  }

  set level(mason.Level level) => _logger.level = level;

  void logTrace(StackTrace stackTrace) {
    final trace = Trace.from(stackTrace).toString();
    _logger
      ..detail('')
      ..detail(trace);

    if (level != mason.Level.verbose) {
      _logger
        ..detail('')
        ..detail(
          'Please run command with  --verbose if you want more information',
        );
    }
  }

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

  mason.Progress progress(String message) {
    final progress = _logger.progress(message);
    if (isVerbose) {
      // if verbose then cancel for other data been displayed and overlapping
      progress.cancel();
      // Replace for a normal log
      info(message);
    }

    return progress;
  }

  // Allows to select from cached sdks.
  String cacheVersionSelector(List<CacheFlutterVersion> versions) {
    // Return message if no cached versions
    if (versions.isEmpty) {
      throw const AppException(
        'No versions installed. Please install'
        ' a version. "fvm install {version}". ',
      );
    }

    /// Ask which version to select

    final versionsList = versions.map((version) => version.name).toList();

    final choice = select('Select a version: ', options: versionsList);

    return choice;
  }

  bool confirm(String? message, {required bool defaultValue}) {
    // When running tests, always return true.
    if (_isTest) return true;

    if (_isCI || _skipInput) {
      info(message ?? '');
      warn('Skipping input confirmation');
      warn('Using default value of $defaultValue');

      return defaultValue;
    }

    return interact.Confirm(prompt: message ?? '', defaultValue: defaultValue)
        .interact();
  }

  String select(
    String? message, {
    required List<String> options,
    int? defaultSelection,
  }) {
    if (_skipInput) {
      if (defaultSelection != null) {
        return options[defaultSelection];
      }
      exit(mason.ExitCode.usage.code);
    }

    final selection = interact.Select(
      prompt: message ?? '',
      options: options,
      initialIndex: defaultSelection ?? 0,
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

  void updateCloneProgress(String line) {
    if (_hasFailedPrint) {
      info('\n');

      return;
    }
    try {
      final matchedEntry = regexes.entries.firstWhereOrNull(
        (entry) => line.contains(entry.key),
      );

      if (matchedEntry != null) {
        final label = matchedEntry.key.padRight(_maxLabelLength);
        final match = matchedEntry.value.firstMatch(line);
        final percentValue = match?.group(1);
        int? percentage = int.tryParse(percentValue ?? '');

        if (percentage != _lastPercentage) {
          if (percentage == null) return;

          if (_lastMatchedEntry.isNotEmpty && _lastMatchedEntry != label) {
            _printProgressBar(_lastMatchedEntry, 100);
            write('\n');
          }

          _printProgressBar(label, percentage);

          _lastPercentage = percentage;
          _lastMatchedEntry = label;
        }
      }
    } catch (e) {
      detail('Failed to update progress bar $e');
      _hasFailedPrint = true;
      _lastMatchedEntry = '';
    }
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

final consoleController = ConsoleController();

/// Console Controller
class ConsoleController {
  /// stdout stream
  final stdout = StreamController<List<int>>();

  /// stderr stream
  final stderr = StreamController<List<int>>();

  /// warning stream
  final warning = StreamController<List<int>>();

  /// fine stream
  final fine = StreamController<List<int>>();

  /// info stream
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

final regexes = {
  'Enumerating objects:': RegExp(r'Enumerating objects: +(\d+)%'),
  'Counting objects:': RegExp(r'Counting objects: +(\d+)%'),
  'Compressing objects:': RegExp(r'Compressing objects: +(\d+)%'),
  'Receiving objects:': RegExp(r'Receiving objects: +(\d+)%'),
  'Resolving deltas:': RegExp(r'Resolving deltas: +(\d+)%'),
};

int _lastPercentage = 0;
String _lastMatchedEntry = '';

final _maxLabelLength =
    regexes.keys.map((e) => e.length).reduce((a, b) => a > b ? a : b);

var _hasFailedPrint = false;
