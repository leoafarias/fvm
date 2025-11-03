import 'package:io/ansi.dart';
import '../services/logger_service.dart';

/// Tracks and displays progress for git clone operations
class GitCloneProgressTracker {
  static const _progressBarWidth = 50;
  static const _progressRegex =
      r'(Enumerating objects:|Counting objects:|Compressing objects:|Receiving objects:|Resolving deltas:).*?(\d+)%';

  final Logger _logger;
  final RegExp _regex = RegExp(_progressRegex);

  int _lastPercentage = -1;
  String _currentPhase = '';

  GitCloneProgressTracker(this._logger);

  void _displayProgress(String phase, int percentage) {
    final label = phase.padRight(20);
    final filled = (percentage / 100 * _progressBarWidth).round();
    final empty = _progressBarWidth - filled;
    final progressBar = green.wrap('[${'█' * filled}${'░' * empty}]');
    _logger.write('\r $label $progressBar $percentage%');
  }

  /// Processes a line of git clone output and updates progress if applicable
  void processLine(String line) {
    try {
      final match = _regex.firstMatch(line);
      if (match == null) return;

      final phase = match.group(1)!;
      final percentage = int.tryParse(match.group(2) ?? '') ?? 0;

      // Complete previous phase when switching
      if (_currentPhase.isNotEmpty && _currentPhase != phase) {
        _displayProgress(_currentPhase, 100);
        _logger.write('\n');
      }

      // Update only if percentage changed
      if (percentage != _lastPercentage) {
        _displayProgress(phase, percentage);
        _lastPercentage = percentage;
        _currentPhase = phase;
      }
    } catch (_) {
      // Ignore parsing errors - git clone continues
    }
  }

  /// Completes the progress tracking and ensures proper formatting
  void complete() {
    if (_currentPhase.isNotEmpty) {
      _logger.write('\n');
    }
  }
}
