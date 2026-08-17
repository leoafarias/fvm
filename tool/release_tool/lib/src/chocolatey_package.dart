import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

const _executableArchivePath = 'fvm/fvm.exe';
const _licenseArchivePath = 'fvm/src/LICENSE';

/// Files staged for a self-contained Chocolatey package.
final class ChocolateyPackageFiles {
  const ChocolateyPackageFiles({
    required this.nuspec,
    required this.executable,
    required this.license,
  });

  final File nuspec;
  final File executable;
  final File license;
}

/// Stages the precompiled Windows x64 executable for `choco pack`.
ChocolateyPackageFiles stageChocolateyPackage({
  required Directory repoRoot,
  required String version,
  Directory? outputDirectory,
}) {
  final archiveFile = File(
    p.join(repoRoot.path, 'build', 'fvm-$version-windows-x64.zip'),
  );
  if (!archiveFile.existsSync()) {
    throw StateError(
      'Windows x64 release archive not found: ${archiveFile.path}. '
      'Run pkg-standalone-windows-x64 first.',
    );
  }

  final nuspecTemplate = File(p.join(repoRoot.path, 'fvm.nuspec'));
  if (!nuspecTemplate.existsSync()) {
    throw StateError('Chocolatey nuspec not found: ${nuspecTemplate.path}');
  }

  final nuspecContents = nuspecTemplate.readAsStringSync();
  if (nuspecContents.contains('dart-sdk')) {
    throw StateError(
      'The Chocolatey package must not depend on the standalone Dart SDK.',
    );
  }

  final archive = ZipDecoder().decodeBytes(
    archiveFile.readAsBytesSync(),
    verify: true,
  );
  final executableBytes = _requiredFileBytes(archive, _executableArchivePath);
  final licenseBytes = _requiredFileBytes(archive, _licenseArchivePath);

  final output =
      outputDirectory ??
      Directory(p.join(repoRoot.path, 'build', 'chocolatey'));
  if (output.existsSync()) {
    output.deleteSync(recursive: true);
  }

  final toolsDirectory = Directory(p.join(output.path, 'tools'))
    ..createSync(recursive: true);
  final nuspec = File(p.join(output.path, 'fvm.nuspec'))
    ..writeAsStringSync(nuspecContents);
  final executable = File(p.join(toolsDirectory.path, 'fvm.exe'))
    ..writeAsBytesSync(executableBytes);
  final license = File(p.join(toolsDirectory.path, 'LICENSE.txt'))
    ..writeAsBytesSync(licenseBytes);

  return ChocolateyPackageFiles(
    nuspec: nuspec,
    executable: executable,
    license: license,
  );
}

List<int> _requiredFileBytes(Archive archive, String path) {
  final entry = archive.findFile(path);
  if (entry == null || !entry.isFile) {
    throw StateError('Required release archive entry not found: $path');
  }

  final content = entry.content;
  if (content is! List<int>) {
    throw StateError('Release archive entry is not binary data: $path');
  }

  return content;
}
