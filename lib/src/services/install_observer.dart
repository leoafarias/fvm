import '../utils/git_clone_progress_tracker.dart';

enum InstallObservationPhase { acquireLock, cloneSdk, validateRevision }

enum InstallObservationStatus { active, complete, skipped }

typedef InstallObservation = ({
  InstallObservationPhase phase,
  InstallObservationStatus status,
  String detail,
  GitCloneProgress? gitProgress,
});

abstract interface class InstallObserver {
  void onUpdate(InstallObservation update);
}

final class CallbackInstallObserver implements InstallObserver {
  final void Function(InstallObservation) callback;

  const CallbackInstallObserver(this.callback);

  @override
  void onUpdate(InstallObservation update) => callback(update);
}
