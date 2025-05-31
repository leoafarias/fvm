import 'package:dart_mappable/dart_mappable.dart';

part 'log_level_model.mapper.dart';

@MappableEnum()
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
