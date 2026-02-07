import '../../domain/entities/user.dart';
import '../repositories/auth_repository.dart';

class LoginWithEmailUseCase {
  final AuthRepository _repository;

  LoginWithEmailUseCase(this._repository);

  Future<User> call(String email, String password) {
    return _repository.loginWithEmail(email, password);
  }
}
