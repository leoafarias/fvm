// https://petri.com/how-to-check-a-powershell-script-is-running-with-admin-privileges
import 'dart:convert';
import 'dart:io';

// Memory permission cache
bool? _permission;

/// Check if it has admin permissions
Future<bool> hasPermission() async {
  if (_permission != null) return Future.value(_permission);
  var process = await Process.start('New-Object', [
    '''Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())'''
  ]);

  // Get first line
  final user = utf8.decode(await process.stdout.first);
  // Wait for process
  await process.exitCode;

  process = await Process.start(
    '''$user.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)''',
    [],
  );

  final isInRole = utf8.decode(await process.stdout.first);

  await process.exitCode;

  _permission = isInRole == 'true';
  return Future.value(_permission);
}
