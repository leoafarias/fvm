/// Provides the current time so registry timestamps can be injected in tests.
class Clock {
  final DateTime Function()? _now;

  const Clock([this._now]);

  DateTime now() => (_now ?? DateTime.now)().toUtc();
}
