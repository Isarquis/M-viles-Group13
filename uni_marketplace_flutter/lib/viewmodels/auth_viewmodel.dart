import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
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

Future<User?> register(String email, String password, String name, String phone, String gender) async {
  setLoading(true);
  try {
    final user = await _authService.register(email, name, phone, gender, password);

    if (user != null) {
      await _firestoreService.registerUserWithGender(
        user.uid,
        {
          'email': email,
          'name': name,
          'phone': phone,
        },
        gender,
      );
    }

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
