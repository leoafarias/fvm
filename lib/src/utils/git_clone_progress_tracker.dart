typedef GitCloneProgress = ({String phase, int percent, String line});

/// Parses progress updates emitted by `git clone --progress`.
final class GitCloneProgressTracker {
  static const _progressPattern =
      r'(Enumerating objects:|Counting objects:|Compressing objects:|Receiving objects:|Resolving deltas:).*?\s(\d+)%';

  final RegExp _regex = RegExp(_progressPattern);
  int _lastPercentage = -1;
  String _currentPhase = '';

  GitCloneProgress? processLine(String line) {
    final match = _regex.firstMatch(line);
    if (match == null) return null;

    final phase = match.group(1)!;
    final percent = int.parse(match.group(2)!);
    if (percent == _lastPercentage && phase == _currentPhase) return null;

    _currentPhase = phase;
    _lastPercentage = percent;

    return (phase: phase, percent: percent, line: line.trim());
  }
}
