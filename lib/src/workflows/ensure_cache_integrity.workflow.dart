import 'package:fvm/fvm.dart';
import 'package:fvm/src/utils/logger.dart';
import 'package:interact/interact.dart';

enum CacheIntegrity { valid, needReinstall, invalid }

Future<CacheIntegrity> ensureCacheIntegrity(CacheVersion version) async {
  final isExecutable = await CacheService.verifyIsExecutable(version);
  final versionsMatch = await CacheService.verifyVersionMatch(version);

  if (!isExecutable) return await _handleNonExecutable(version);
  if (!versionsMatch) return await _handleVersionMismatch(version);

  logger.detail('Flutter SDK: ${version.name} is properly setup.');
  return CacheIntegrity.valid;
}

Future<CacheIntegrity> _handleNonExecutable(CacheVersion version) async {
  logger
    ..notice(
        'Flutter SDK: ${version.name} - cannot be executed. It may be corrupt.')
    ..spacer;

  final shouldReinstall = logger.confirm(
      'Would you like to remove and reinstall it?',
      defaultValue: true);

  if (shouldReinstall) {
    CacheService.remove(version);
    return CacheIntegrity.needReinstall;
  }

  return CacheIntegrity.invalid;
}

Future<CacheIntegrity> _handleVersionMismatch(CacheVersion version) async {
  logger
    ..notice(
        'Flutter SDK: ${version.name} - version name does not match the cached version which is ${version.sdkVersion}.')
    ..info('${version.sdkVersion} can be found at ${version.dir.path}')
    ..info('Should be ${version.sdkVersion}')
    ..info(
        'This can happen due to running the command "flutter upgrade" directly on the cache version.');

  final selectedOption = Select(
          prompt: 'How would you like to fix the problem?',
          options: [
            'Move ${version.sdkVersion} version to the correct cache directory, and reinstall ${version.name}',
            'Remove incorrect version and reinstall ${version.name}',
            'Do nothing'
          ],
          initialIndex: 0)
      .interact();

  if (selectedOption == 2) return CacheIntegrity.invalid;
  if (selectedOption == 0) {
    CacheService.moveToSdkVersionDiretory(version);
  }
  if (selectedOption == 1) {
    CacheService.remove(version);
  }

  return CacheIntegrity.needReinstall;
}
