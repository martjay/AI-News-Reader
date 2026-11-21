/// Runs async jobs one after another. Later jobs see state updates from earlier ones.
class Serial {
  Future<void> _tail = Future<void>.value();

  Future<T> run<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then((_) {}, onError: (_, _) {});
    return result;
  }
}

/// Coalesces overlapping refresh requests into the current run plus one follow-up.
class RefreshGate {
  var _running = false;
  var _again = false;

  bool request() {
    if (_running) {
      _again = true;
      return false;
    }
    _running = true;
    return true;
  }

  bool finish() {
    if (_again) {
      _again = false;
      return true;
    }
    _running = false;
    return false;
  }
}
