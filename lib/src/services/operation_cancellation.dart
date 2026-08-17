abstract interface class OperationCancellation {
  bool get isCancelled;

  void cancel();
}
