import 'dart:io';

/// Replaces [target] with [staged].
///
/// POSIX can rename over [target] in one step. When that is rejected (Windows
/// when the destination exists, or a missing staged file), the previous
/// [target] is moved aside first and restored if the replacement cannot be
/// applied.
void replaceFileAtomically({required File target, required File staged}) {
  try {
    staged.renameSync(target.path);

    return;
  } on FileSystemException {
    // Fall through to a backup replace that can restore [target].
  }

  final backup = File('${target.path}.bak');
  FileSystemException? failure;
  try {
    if (backup.existsSync()) {
      backup.deleteSync();
    }
    if (target.existsSync()) {
      target.renameSync(backup.path);
    }
    staged.renameSync(target.path);
  } on FileSystemException catch (error) {
    failure = error;
    if (backup.existsSync() && !target.existsSync()) {
      try {
        backup.renameSync(target.path);
      } on FileSystemException {
        // Keep [failure]; a leftover .bak is better than inventing a new error.
      }
    }
  }

  if (backup.existsSync() && target.existsSync()) {
    try {
      backup.deleteSync();
    } on FileSystemException {
      // The replacement already succeeded.
    }
  }

  if (failure != null) {
    throw failure;
  }
}
