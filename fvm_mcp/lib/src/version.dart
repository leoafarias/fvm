import 'dart:io';

final _versionRe = RegExp(r'^(?:fvm\s+)?(\d+)\.(\d+)\.(\d+)');

class FvmVersion {
  final int major;
  final int minor;
  final int patch;
  final String raw;

  const FvmVersion(this.major, this.minor, this.patch, this.raw);

  bool get isUnknown => raw.trim().isEmpty || raw.trim() == 'unknown';

  bool get supportsJsonApi =>
      (major > 3) || (major == 3 && (minor > 1 || (minor == 1 && patch >= 2)));
  bool get supportsSkipInput => (major > 3) || (major == 3 && minor >= 2);

  @override
  String toString() => raw;
}

Future<FvmVersion> detectFvmVersion() async {
  try {
    final res = await Process.run('fvm', ['--version'], runInShell: true);
    final stdoutObj = res.stdout;
    final stdout = stdoutObj is String
        ? stdoutObj
        : stdoutObj is List<int>
            ? String.fromCharCodes(stdoutObj)
            : '${res.stdout}';
    final match = _versionRe.firstMatch(stdout);
    if (match != null) {
      final major = int.parse(match.group(1)!);
      final minor = int.parse(match.group(2)!);
      final patch = int.parse(match.group(3)!);
      return FvmVersion(major, minor, patch, '$major.$minor.$patch');
    }
    // Fallback when version is not in semantic form.
    return FvmVersion(0, 0, 0, stdout.trim());
  } catch (_) {
    return const FvmVersion(0, 0, 0, 'unknown');
  }
}
