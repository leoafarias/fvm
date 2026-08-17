import '../../utils/context.dart';

typedef FvmContextReloader = FvmContext Function(FvmContext previous);

final class FvmContextHandle {
  FvmContext current;
  final FvmContextReloader _reload;

  FvmContextHandle(this.current, {required FvmContextReloader reload})
    : _reload = reload;

  void reloadFromDisk() => current = _reload(current);
}

FvmContext reloadFvmContextFromDisk(FvmContext previous) => FvmContext.create(
  debugLabel: previous.debugLabel,
  workingDirectoryOverride: previous.workingDirectory,
  environmentOverrides: previous.environment,
  appConfigPath: previous.appConfigPath,
  skipInput: false,
  stdinHasTerminal: previous.stdinHasTerminal,
  logLevel: previous.logLevel,
  isTest: previous.isTest,
);
