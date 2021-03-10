class InternalError implements Exception {
  final String message;
  const InternalError([this.message = '']);
  @override
  String toString() => 'Internal Error: $message';
}

/// Could not fetch Flutter releases
