import 'package:fvm/src/models/cache_flutter_version_model.dart';
import 'package:fvm/src/services/logger_service.dart';
import 'package:fvm/src/utils/context.dart';

/// Test logger that allows simulating user input
class TestLogger extends Logger {
  final Map<String, bool> _confirmResponses = {};
  final Map<String, int> _selectResponses = {};
  final Map<String, String> _versionResponses = {};

  TestLogger(FvmContext context) : super(context);

  /// Set a response for a specific confirmation prompt
  void setConfirmResponse(String promptPattern, bool response) {
    _confirmResponses[promptPattern] = response;
  }

  /// Set a response for a specific selection prompt
  void setSelectResponse(String promptPattern, int optionIndex) {
    _selectResponses[promptPattern] = optionIndex;
  }

  /// Set a response for a specific version selection prompt
  void setVersionResponse(String promptPattern, String version) {
    _versionResponses[promptPattern] = version;
  }

  @override
  bool confirm(String? message, {required bool defaultValue}) {
    // Store the message in outputs like the parent
    if (message != null) {
      outputs.add(message);
    }

    // Check if we have a predefined response for this prompt
    if (message != null) {
      for (final entry in _confirmResponses.entries) {
        if (message.contains(entry.key)) {
          info('User response: ${entry.value ? "Yes" : "No"}');
          return entry.value;
        }
      }
    }

    // Fall back to parent behavior
    return super.confirm(message, defaultValue: defaultValue);
  }

  @override
  String select(
    String? message, {
    required List<String> options,
    int? defaultSelection,
  }) {
    if (message != null) {
      outputs.add(message);
      for (final entry in _selectResponses.entries) {
        if (message.contains(entry.key)) {
          final index = entry.value;
          if (index >= 0 && index < options.length) {
            info('User selected: ${options[index]}');
            return options[index];
          }
        }
      }
    }
    return super.select(
      message,
      options: options,
      defaultSelection: defaultSelection,
    );
  }

  @override
  String cacheVersionSelector(List<CacheFlutterVersion> versions) {
    final prompt = 'Select a version: ';
    outputs.add(prompt);
    for (final entry in _versionResponses.entries) {
      if (prompt.contains(entry.key)) {
        info('User selected version: ${entry.value}');
        return entry.value;
      }
    }
    return super.cacheVersionSelector(versions);
  }
}
