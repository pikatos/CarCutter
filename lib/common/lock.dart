import 'dart:async';

class Lock {
  Completer<void>? _token;

  Future<void> lock() async {
    while (_token != null) {
      await _token!.future;
    }
    _token = Completer();
  }

  void release() {
    final prevToken = _token;
    _token = null;
    prevToken?.complete();
  }
}
