// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'log_level_model.dart';

class LevelMapper extends EnumMapper<Level> {
  LevelMapper._();

  static LevelMapper? _instance;
  static LevelMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = LevelMapper._());
    }
    return _instance!;
  }

  static Level fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  Level decode(dynamic value) {
    switch (value) {
      case r'verbose':
        return Level.verbose;
      case r'debug':
        return Level.debug;
      case r'info':
        return Level.info;
      case r'warning':
        return Level.warning;
      case r'error':
        return Level.error;
      case r'critical':
        return Level.critical;
      case r'quiet':
        return Level.quiet;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(Level self) {
    switch (self) {
      case Level.verbose:
        return r'verbose';
      case Level.debug:
        return r'debug';
      case Level.info:
        return r'info';
      case Level.warning:
        return r'warning';
      case Level.error:
        return r'error';
      case Level.critical:
        return r'critical';
      case Level.quiet:
        return r'quiet';
    }
  }
}

extension LevelMapperExtension on Level {
  String toValue() {
    LevelMapper.ensureInitialized();
    return MapperContainer.globals.toValue<Level>(this) as String;
  }
}
