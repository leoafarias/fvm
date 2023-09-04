bool isGitCommit(String hash) {
  final RegExp regExp = RegExp(r'^[0-9a-f]{4,40}$');
  return regExp.hasMatch(hash);
}
