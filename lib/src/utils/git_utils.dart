bool isPossibleGitCommit(String hash) {
  // Trim whitespace and normalize to lowercase
  final normalized = hash.trim().toLowerCase();

  return _isValidShortCommitSha(normalized) ||
      _isValidFullCommitSha(normalized);
}

bool _isValidShortCommitSha(String str) {
  // Keep the practical 7-10 range but handle uppercase
  return RegExp(r'^[a-f0-9]{7,10}$').hasMatch(str);
}

bool _isValidFullCommitSha(String str) {
  return RegExp(r'^[a-f0-9]{40}$').hasMatch(str);
}
