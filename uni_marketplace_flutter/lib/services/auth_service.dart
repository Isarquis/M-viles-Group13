import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  Future<User?> login(String email, String password) async {
    try {
      print('Logging in with email: $email'); // DEBUG LOG
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'Unexpected error during login: $e';
    }
  }

  Future<User?> register(
    String email,
    String name,
    String phone,
    String gender,
    String password, {
    File? profileImageFile,
  }) async {
    try {
      print('Registering user with email: $email'); // DEBUG LOG

      final result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (result.user != null) {
        // Datos a enviar a Firestore
        final userData = {
          'email': email.trim(),
          'name': name.trim(),
          'phone': phone.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        };

        // Llamar a registerUserWithGender en FirestoreService
        await _firestoreService.registerUserWithGender(
          result.user!.uid,
          userData,
          gender,
          profileImageFile: profileImageFile,
        );
      }

      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'Unexpected error during registration: $e';
    }
  }

  Future<void> logout() async {
    print('Logging out...');
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  String _handleAuthError(FirebaseAuthException e) {
    print('Auth Error: ${e.code}'); // DEBUG LOG
    switch (e.code) {
      case 'network-request-failed':
        return 'No internet connection.';
      case 'user-not-found':
        return 'Account not found.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'Email already registered.';
      case 'invalid-email':
        return 'Invalid email format.';
      case 'weak-password':
        return 'Password too weak.';
      default:
        return 'Authentication error. Try again.';
    }
  }
}
