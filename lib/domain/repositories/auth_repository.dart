import '../../domain/entities/user.dart';

abstract class AuthRepository {
  Future<User> loginWithEmail(String email, String password);
  Future<User> registerWithEmail(String email, String password, String displayName);
  Future<User> loginWithGoogle();
  Future<User> loginWithFacebook();
  Future<User> loginWithApi(String email, String password);
  Future<void> logout();
  Future<void> deleteAccount();
  User? getCurrentUser();
  Stream<User?> authStateChanges();
}
