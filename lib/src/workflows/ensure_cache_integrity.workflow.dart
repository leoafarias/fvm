import 'package:fvm/fvm.dart';
import 'package:fvm/src/utils/logger.dart';
import 'package:interact/interact.dart';

/// Returns [true] if cache is
Future<CacheIntegrity> ensureCacheIntegrity(CacheVersion version) async {
  final isExecutable = await CacheService.verifyIsExecutable(version);
  final versionsMatch = await CacheService.verifyVersionMatch(version);
  final versionName = version.name;

  if (!isExecutable) {
    logger
      ..notice(
        'Flutter SDK: $versionName - cannot be executed. It may be corrupt.',
      )
      ..spacer;

    final shouldReinstall = logger.confirm(
      'Would you like to remove and reinstall it?',
      defaultValue: true,
    );

    if (shouldReinstall) {
      // Removing
      CacheService.remove(version);
      return CacheIntegrity.needReinstall();
    }

    return CacheIntegrity.invalid();
  } else if (!versionsMatch) {
    logger.notice(
      'Flutter SDK: $versionName - version name does not match the cached version which is ${version.sdkVersion}}}',
    );

    logger.info(
      '${version.sdkVersion}} can be found at ${version.dir.path}',
    );

    logger.info('Should be ${version.sdkVersion}');
    logger.info(
      'This can happen due to running the command "flutter upgrade" directly on the cache version.',
    );

    final selectedOption = Select(
      prompt: 'How would you like to fix the problem?',
      options: [
        'Move ${version.sdkVersion} version to the correct cache directory, and reinstall $versionName',
        'Remove incorrect version and reinstall $versionName',
        'Do nothing'
      ],
      initialIndex: 0, // optional, will be 0 by default
    ).interact();
    // Do nothing
    if (selectedOption == 2) {
      return CacheIntegrity.invalid();
    }

    /// Move and reinstall
    if (selectedOption == 0) {
      // Removing
      CacheService.moveToSdkVersionDiretory(
        version,
      );

      // Remove and reinstall
    } else if (selectedOption == 1) {
      // Removing
      CacheService.remove(version);
    }

    return CacheIntegrity.needReinstall();
  }

  logger
    ..detail('')
    ..detail('Flutter SDK: $versionName is properly setup.')
    ..detail('');

  return CacheIntegrity.isValid();
}

class CacheIntegrity {
  final bool _isValid;
  final bool _needReinstall;

  CacheIntegrity({
    required bool isValid,
    required bool needReinstall,
  })  : _isValid = isValid,
        _needReinstall = needReinstall;

  factory CacheIntegrity.isValid() {
    return CacheIntegrity(
      isValid: true,
      needReinstall: false,
    );
  }

  factory CacheIntegrity.needReinstall() {
    return CacheIntegrity(
      isValid: false,
      needReinstall: true,
    );
  }

  factory CacheIntegrity.invalid() {
    return CacheIntegrity(
      isValid: false,
      needReinstall: false,
    );
  }

  bool get isInvalid => !_isValid && !_needReinstall;

  bool get isNeedReinstall => _needReinstall;

  bool get isValid => _isValid;
}
