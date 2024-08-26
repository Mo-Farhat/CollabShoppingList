import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore instance

  User? get user => _auth.currentUser;

  Future<void> signInWithEmailPassword(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      // Save user info in Firestore after sign-in
      await _saveUserToFirestore(user);
    } on FirebaseAuthException catch (e) {
      throw _getAuthExceptionMessage(e);
    }
  }

  Future<void> signUpWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);

      // Save user info in Firestore after sign-up
      await _saveUserToFirestore(userCredential.user);
    } on FirebaseAuthException catch (e) {
      throw _getAuthExceptionMessage(e);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Method to save user info to Firestore
  Future<void> _saveUserToFirestore(User? user) async {
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'email': user.email,
        'uid': user.uid,
      });
    }
  }

  String _getAuthExceptionMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'The email address is badly formatted.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Incorrect password provided for that user.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'operation-not-allowed':
        return 'Operation not allowed. Please contact support.';
      default:
        return 'An unknown error occurred.';
    }
  }
}
