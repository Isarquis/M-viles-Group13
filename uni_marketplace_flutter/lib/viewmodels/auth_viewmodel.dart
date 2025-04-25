import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  Future<User?> login(String email, String password) async {
    setLoading(true);
    try {
      final user = await _authService.login(email, password);
      _setError(null);
      return user;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      setLoading(false);
    }
  }

  Future<User?> register(String email, String password) async {
   setLoading(true);
    try {
      final user = await _authService.register(email, password);
      _setError(null);
      return user;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
    setLoading(false);
    }
  }

  void setLoading(bool val) {
    _loading = val;
    notifyListeners();
  }

  void _setError(String? val) {
    _error = val;
    notifyListeners();
  }
}
