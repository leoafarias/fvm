import 'dart:io';
import 'dart:math';

import '../models/cache_flutter_version_model.dart';
import 'extensions.dart';

Future<int> getDirectorySize(Directory dir) async {
  int total = 0;

  // Using async/await to asynchronously handle the file system's directories and files
  await for (FileSystemEntity entity in dir.list(recursive: true)) {
    if (entity is File) {
      // Accumulate file size
      total += await entity.length();
    }
  }

  return total;
}

Future<int> getFullDirectorySize(List<CacheFlutterVersion> versions) async {
  final promises = <Future<int>>[];

  final directories = versions.map((version) => version.directory.dir).toList();

  for (var dir in directories) {
    promises.add(getDirectorySize(dir));
  }

  final sizes = await Future.wait(promises);

  // Sum all sizes
  return sizes.fold<int>(0, (a, b) => a + b);
}

String formatBytes(int bytes, [int decimals = 2]) {
  if (bytes <= 0) return "0 B";
  const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
  var i = (log(bytes) / log(1000)).floor();

  return '${(bytes / pow(1000, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
}
