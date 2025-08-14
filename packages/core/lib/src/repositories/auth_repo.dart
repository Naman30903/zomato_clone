import 'package:core/src/models/user.dart';
import 'package:core/src/models/enums.dart';

abstract class AuthRepo {
  Future<User?> getCurrentUser();
  Future<User> signIn(String email, String password);
  Future<User> signUp(
    String name,
    String email,
    String password,
    UserRole role,
  );
  Future<void> signOut();
  Future<User> updateProfile(User user);
  Future<bool> resetPassword(String email);
  Stream<User?> get authStateChanges;
}
