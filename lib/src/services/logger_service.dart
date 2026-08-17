import 'dart:async';

import 'package:dart_console/dart_console.dart';
import 'package:interact/interact.dart' as interact;
import 'package:mason_logger/mason_logger.dart' as mason;
import 'package:stack_trace/stack_trace.dart';
import 'package:tint/tint.dart';

import '../models/cache_flutter_version_model.dart';
import '../models/log_level_model.dart';
import '../utils/exceptions.dart';
import 'base_service.dart';

enum LogEventLevel { info, success, warning, error, debug }

typedef LogEvent = ({LogEventLevel level, String message});

abstract interface class LogProgress {
  void complete([String? message]);

  void fail([String? message]);

  void cancel([String? message]);
}

abstract interface class LogSink {
  void add(LogEvent event);

  LogProgress startProgress(String message);
}

final class _MasonLogProgress implements LogProgress {
  final mason.Progress _progress;

  const _MasonLogProgress(this._progress);

  @override
  void cancel([String? message]) => _progress.cancel();

  @override
  void complete([String? message]) => _progress.complete(message);

  @override
  void fail([String? message]) => _progress.fail(message);
}

mason.Level _toMasonLevel(Level level) {
  return mason.Level.values.firstWhere((e) => e.name == level.name);
}

Level _toLogLevel(mason.Level level) {
  return Level.values.firstWhere((e) => e.name == level.name);
}

class Logger extends ContextualService {
  static final Object _sinkZoneKey = Object();

  final mason.Logger _logger;
  final bool _skipInput;
  final List<String> _outputs = [];

  Logger(super.context)
    : _logger = mason.Logger(level: _toMasonLevel(context.logLevel)),
      _skipInput = context.skipInput;

  void _emit(
    LogEventLevel level,
    String message,
    void Function() writeToMason,
  ) {
    _outputs.add(message);
    final sink = _activeSink;
    if (sink != null) {
      sink.add((level: level, message: message));

      return;
    }
    writeToMason();
  }

  LogSink? get _activeSink => Zone.current[_sinkZoneKey] as LogSink?;

  bool get isVerbose => level == Level.verbose;

  Level get level => _toLogLevel(_logger.level);

  List<String> get outputs => _outputs;

  set level(Level level) => _logger.level = _toMasonLevel(level);

  Future<T> runWithSink<T>(LogSink sink, Future<T> Function() action) {
    return runZoned(action, zoneValues: {_sinkZoneKey: sink});
  }

  void logTrace(StackTrace stackTrace) {
    final trace = Trace.from(stackTrace).toString();
    debug('');
    debug(trace);

    if (level != Level.verbose) {
      debug('');
      debug('Please run command with  --verbose if you want more information');
    }
  }

  void info([String message = '']) {
    _emit(LogEventLevel.info, message, () => _logger.info(message));
  }

  void infoToStderr([String message = '']) {
    _emit(
      LogEventLevel.info,
      message,
      () => _logger.err(message, style: _logger.theme.info),
    );
  }

  void success(String message) {
    final formatted = '${Icons.success.green()} $message';
    _emit(LogEventLevel.success, formatted, () => _logger.info(formatted));
  }

  void fail(String message) {
    final formatted = '${Icons.failure.red()} $message';
    _emit(LogEventLevel.error, formatted, () => _logger.info(formatted));
  }

  void warn([String message = '']) {
    _emit(LogEventLevel.warning, message, () => _logger.warn(message));
  }

  void warnToStderr([String message = '']) {
    _emit(
      LogEventLevel.warning,
      message,
      () => _logger.err(message, style: _logger.theme.warn),
    );
  }

  void err([String message = '']) {
    _emit(LogEventLevel.error, message, () => _logger.err(message));
  }

  void debug([String message = '']) {
    _emit(LogEventLevel.debug, message, () => _logger.detail(message));
  }

  void write(String message) {
    _emit(LogEventLevel.info, message, () => _logger.write(message));
  }

  LogProgress progress(String message) {
    _outputs.add(message);
    final sink = _activeSink;
    if (sink != null) return sink.startProgress(message);
    final progress = _logger.progress(message);
    if (isVerbose) {
      // if verbose then cancel for other data been displayed and overlapping
      progress.cancel();
      // Replace for a normal log
      _logger.info(message);
    }

    return _MasonLogProgress(progress);
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

    final versionsList = versions
        .map((version) => version.nameWithAlias)
        .toList();

    final choice = select('Select a version: ', options: versionsList);

    return choice;
  }

  bool confirm(String? message, {required bool defaultValue}) {
    if (_skipInput) {
      info(message ?? '');
      warn('Skipping input confirmation');
      warn('Using default value of $defaultValue');

      return defaultValue;
    }

    return interact.Confirm(
      prompt: message ?? '',
      defaultValue: defaultValue,
    ).interact();
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
      throw ForceExit('', mason.ExitCode.usage.code);
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

    write(table.toString());
  }

  void important(String message) {
    // Add 2 due to the warning icon.

    final label = '${Icons.success} $message'.cyan();

    final table = Table()
      ..insertRow([label])
      ..borderColor = ConsoleColor.cyan
      ..borderType = BorderType.outline
      ..borderStyle = BorderStyle.square;

    final output = table.toString();
    _emit(LogEventLevel.success, output, () => _logger.write(output));
  }
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
