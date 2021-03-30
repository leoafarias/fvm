class FvmInternalError implements Exception {
  final String message;
  const FvmInternalError([this.message = '']);
  @override
  String toString() => 'Internal Error: $message';
}

class FvmUsageException implements Exception {
  final String message;
  const FvmUsageException([this.message = '']);
  @override
  String toString() => 'Usage Exception: $message';
}

/// Could not fetch Flutter releases
