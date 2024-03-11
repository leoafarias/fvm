// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'channels_model.dart';

class FlutterChannelMapper extends EnumMapper<FlutterChannel> {
  FlutterChannelMapper._();

  static FlutterChannelMapper? _instance;
  static FlutterChannelMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = FlutterChannelMapper._());
    }
    return _instance!;
  }

  static FlutterChannel fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  FlutterChannel decode(dynamic value) {
    switch (value) {
      case 'stable':
        return FlutterChannel.stable;
      case 'dev':
        return FlutterChannel.dev;
      case 'beta':
        return FlutterChannel.beta;
      case 'master':
        return FlutterChannel.master;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(FlutterChannel self) {
    switch (self) {
      case FlutterChannel.stable:
        return 'stable';
      case FlutterChannel.dev:
        return 'dev';
      case FlutterChannel.beta:
        return 'beta';
      case FlutterChannel.master:
        return 'master';
    }
  }
}

extension FlutterChannelMapperExtension on FlutterChannel {
  String toValue() {
    FlutterChannelMapper.ensureInitialized();
    return MapperContainer.globals.toValue<FlutterChannel>(this) as String;
  }
}
