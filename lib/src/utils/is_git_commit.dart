bool isGitCommit(String hash) {
  return isShortCommit(hash) || isLongCommit(hash);
}

bool isShortCommit(String commit) {
  return RegExp(r'^[0-9a-f]{7,8}$').hasMatch(commit);
}

bool isLongCommit(String commit) {
  return RegExp(r'^[0-9a-f]{40}$').hasMatch(commit);
}
