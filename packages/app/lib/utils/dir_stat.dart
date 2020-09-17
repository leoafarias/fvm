import 'dart:io';

import 'package:filesize/filesize.dart';

class DirectorySizeInfo {
  final int fileCount;
  final int totalSize;
  final String friendlySize;
  DirectorySizeInfo({
    this.fileCount,
    this.totalSize,
    this.friendlySize,
  });
}

Future<DirectorySizeInfo> getDirectorySize(String dirPath) async {
  var fileCount = 0;
  var totalSize = 0;
  var dir = Directory(dirPath);
  try {
    if (await dir.exists()) {
      await dir.list(recursive: true, followLinks: false).forEach((entity) {
        if (entity is File) {
          fileCount++;
          totalSize += entity.lengthSync();
        }
      });
    }
  } on Exception catch (e) {
    print(e.toString());
  }

  return DirectorySizeInfo(
    fileCount: fileCount,
    totalSize: totalSize,
    friendlySize: filesize(totalSize),
  );
}
