bool isGitCommit(String hash) {
  return _isValidShortCommitSha(hash) || _isValidFullCommitSha(hash);
}

bool _isValidShortCommitSha(String str) {
  return RegExp(r'^[a-f0-9]{7,10}$').hasMatch(str);
}

bool _isValidFullCommitSha(String str) {
  return RegExp(r'^[a-f0-9]{40}$').hasMatch(str);
}
