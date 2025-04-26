import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> login(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

Future<User?> register(String email, String password, String name, String phone, String gender) async {
  try {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );


    if (result.user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(result.user!.uid)
          .set({
        'email': email.trim(),
        'name': name.trim(),
        'phone': phone.trim(),
        'gender': gender.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return result.user;
  } on FirebaseAuthException catch (e) {
    throw _handleAuthError(e);
  } catch (e) {
    throw 'An unexpected error occurred. Please try again.';
  }
}


  Future<void> logout() async {
    await _auth.signOut();
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Handle FirebaseAuth specific error messages
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'network-request-failed':
        return 'No internet connection. Please check your network and try again.';
      case 'user-not-found':
        return 'No account found for that email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'weak-password':
        return 'The password is too weak. Please use a stronger one.';
      default:
        return 'Authentication error. Please try again later.';
    }
  }
}
