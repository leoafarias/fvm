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
      case 'verbose':
        return Level.verbose;
      case 'debug':
        return Level.debug;
      case 'info':
        return Level.info;
      case 'warning':
        return Level.warning;
      case 'error':
        return Level.error;
      case 'critical':
        return Level.critical;
      case 'quiet':
        return Level.quiet;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(Level self) {
    switch (self) {
      case Level.verbose:
        return 'verbose';
      case Level.debug:
        return 'debug';
      case Level.info:
        return 'info';
      case Level.warning:
        return 'warning';
      case Level.error:
        return 'error';
      case Level.critical:
        return 'critical';
      case Level.quiet:
        return 'quiet';
    }
  }
}

extension LevelMapperExtension on Level {
  String toValue() {
    LevelMapper.ensureInitialized();
    return MapperContainer.globals.toValue<Level>(this) as String;
  }
}
