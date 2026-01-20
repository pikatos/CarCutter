import 'package:flutter/foundation.dart';

class OfflineStatus with ChangeNotifier {
  bool _isOffline = false;

  bool get isOffline => _isOffline;

  void setOffline(bool value) {
    _isOffline = value;
    notifyListeners();
  }
}
