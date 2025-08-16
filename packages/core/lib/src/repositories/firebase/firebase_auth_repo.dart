import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:core/src/models/user.dart';
import 'package:core/src/models/enums.dart';
import 'package:core/src/repositories/auth_repo.dart';

class FirebaseAuthRepo implements AuthRepo {
  final firebase_auth.FirebaseAuth _firebaseAuth;

  FirebaseAuthRepo({firebase_auth.FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance;

  @override
  Future<User?> getCurrentUser() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;

    // Get user data from Firestore or user claims
    return _mapFirebaseUser(firebaseUser);
  }

  @override
  Future<User> signIn(String email, String password) async {
    try {
      final result = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user == null) {
        throw Exception('Authentication failed');
      }

      return _mapFirebaseUser(result.user!);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    }
  }

  @override
  Future<User> signUp(
    String name,
    String email,
    String password,
    UserRole role,
  ) async {
    try {
      // Create the user with email and password
      final result = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user == null) {
        throw Exception('Failed to create account');
      }

      // Update display name
      await result.user!.updateDisplayName(name);
      return User(
        id: result.user!.uid,
        name: name,
        email: email,
        phoneNumber: result.user!.phoneNumber ?? '',
        profileImageUrl: result.user!.photoURL,
        role: role,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    }
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  @override
  Future<User> updateProfile(User user) async {
    if (_firebaseAuth.currentUser != null) {
      await _firebaseAuth.currentUser!.updateDisplayName(user.name);
    }

    return user;
  }

  @override
  Future<bool> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Stream<User?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      if (firebaseUser == null) return null;
      return _mapFirebaseUser(firebaseUser);
    });
  }

  // Helper method to map Firebase User to our User model
  User _mapFirebaseUser(firebase_auth.User firebaseUser) {
    return User(
      id: firebaseUser.uid,
      name: firebaseUser.displayName ?? 'User',
      email: firebaseUser.email ?? '',
      phoneNumber: firebaseUser.phoneNumber ?? '',
      profileImageUrl: firebaseUser.photoURL,
      role: UserRole.customer,
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
      updatedAt: firebaseUser.metadata.lastSignInTime ?? DateTime.now(),
    );
  }

  // Helper method to handle Firebase Auth exceptions
  Exception _handleFirebaseAuthError(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('No user found with this email');
      case 'wrong-password':
        return Exception('Wrong password');
      case 'email-already-in-use':
        return Exception('Email is already in use by another account');
      case 'weak-password':
        return Exception('The password is too weak');
      case 'invalid-email':
        return Exception('Invalid email address');
      case 'operation-not-allowed':
        return Exception('Operation not allowed');
      case 'too-many-requests':
        return Exception('Too many requests. Try again later');
      case 'user-disabled':
        return Exception('This user has been disabled');
      default:
        return Exception(e.message ?? 'An unknown error occurred');
    }
  }
}
