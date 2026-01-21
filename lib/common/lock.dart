import 'dart:async';

class Lock {
  Completer<void>? _token;

  Future<void> lock() async {
    while (_token != null) {
      await _token!.future;
    }
    _token = Completer();
  }

  Future<bool> tryLock() async {
    if (_token != null) {
      return false;
    }
    _token = Completer();
    return true;
  }

  void release() {
    final prevToken = _token;
    _token = null;
    prevToken?.complete();
  }
}
