import 'package:path/path.dart' as p;

/// Replaces all backslashes with forward slashes.
///
/// Useful to make Windows paths compatible with Posix systems.
String convertToPosixPath(String path) => path.replaceAll(r'\', '/');

/// Resolves the Flutter SDK path written to VS Code settings.
String resolveVsCodeSdkPath(
  String sdkPath, {
  required bool privilegedAccess,
  required String relativeTo,
}) {
  final resolvedPath =
      privilegedAccess ? p.relative(sdkPath, from: relativeTo) : sdkPath;

  return convertToPosixPath(resolvedPath);
}
