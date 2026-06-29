import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

/// Holds the logged-in user and exposes login/register/logout to the UI.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  bool _busy = false;

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get busy => _busy;

  /// Try to log in automatically using a saved token (used by SplashScreen).
  Future<bool> tryAutoLogin() async {
    await _authService.loadSavedToken();
    final token = await _authService.getSavedToken();
    if (token == null || token.isEmpty) return false;

    try {
      _user = await _authService.me();
      notifyListeners();
      return true;
    } catch (_) {
      return false; // token missing/expired -> go to login
    }
  }

  Future<void> login(String email, String password) async {
    _setBusy(true);
    try {
      final fcmToken = await NotificationService.getFCMToken();
      _user = await _authService.login(
        email: email,
        password: password,
        fcmToken: fcmToken,
      );
    } finally {
      _setBusy(false);
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
  }) async {
    _setBusy(true);
    try {
      final fcmToken = await NotificationService.getFCMToken();
      _user = await _authService.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        phone: phone,
        fcmToken: fcmToken,
      );
    } finally {
      _setBusy(false);
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }

  void _setBusy(bool value) {
    _busy = value;
    notifyListeners();
  }
}
