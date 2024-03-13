/// Replaces all backslashes with forward slashes.
///
/// Useful to make Windows paths compatible with Posix systems.
String convertToPosixPath(String path) => path.replaceAll(r'\', '/');
