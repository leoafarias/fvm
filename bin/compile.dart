import 'dart:io';

Future<void> main() async {
  const package = 'fvm'; // Your package name
  const destination =
      '/usr/local/bin'; // system location for user installed binaries

  // Identify the operating system
  var os = Platform.operatingSystem;

  if (os != 'macos' && os != 'linux') {
    print('Unsupported OS. Only MacOS and Linux are supported.');
    return;
  }

  // Get temporary directory
  var tempDir = await Directory.systemTemp.createTemp('fvm-compile');

  var tempFile = File('${tempDir.path}/$package-$os');

  // Compile the package to native executable
  print('Compiling package...');
  final compileResult = await Process.run(
    'dart',
    ['compile', 'exe', 'bin/main.dart', '-o', tempFile.path],
  );

  // Error checking for compile process
  if (compileResult.exitCode != 0) {
    print('Error occurred in compilation:\n ${compileResult.stderr}');
    return;
  }

  print('Compilation successful.');
  print('Moving compiled package to destination...');

  // Move the compiled executable to desired directory

  // Make sure your Dart application has the necessary permissions for this operation
  if (await tempFile.exists()) {
    await tempFile.rename('$destination/$package');
    print('Executable moved successfully');
  } else {
    print('Failed moving the binary. File does not exist.');
  }

  // Clean up the temp directory
  await tempDir.delete();

  // Deactivate current globally activated version of FVM
  final deactivateResult =
      await Process.run('dart', ['pub', 'global', 'deactivate', 'fvm']);
  if (deactivateResult.exitCode == 0) {
    print('Deactivated current global version of FVM successfully');
  } else {
    print('Error during the deactivation of the global FVM version');
  }
}
