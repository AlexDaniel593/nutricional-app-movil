import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_firebase_datasource.dart';
import '../datasources/auth_api_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthFirebaseDatasource _datasource;
  final AuthApiDatasource _apiDatasource;

  AuthRepositoryImpl(this._datasource, [AuthApiDatasource? apiDatasource])
      : _apiDatasource = apiDatasource ?? AuthApiDatasource();

  @override
  Future<User> loginWithEmail(String email, String password) {
    return _datasource.loginWithEmail(email, password);
  }

  @override
  Future<User> registerWithEmail(String email, String password, String displayName) {
    return _datasource.registerWithEmail(email, password, displayName);
  }

  @override
  Future<User> loginWithGoogle() {
    return _datasource.loginWithGoogle();
  }

  @override
  Future<User> loginWithFacebook() {
    return _datasource.loginWithFacebook();
  }

  @override
  Future<User> loginWithApi(String email, String password) {
    return _apiDatasource.loginWithApi(email, password);
  }

  @override
  Future<void> logout() {
    return _datasource.logout();
  }

  @override
  Future<void> deleteAccount() {
    return _datasource.deleteAccount();
  }

  @override
  User? getCurrentUser() {
    return _datasource.getCurrentUser();
  }

  @override
  Stream<User?> authStateChanges() {
    return _datasource.authStateChanges();
  }
}
