import '../../domain/entities/user.dart';
import '../repositories/auth_repository.dart';

class LoginWithApiUseCase {
  final AuthRepository _repository;

  LoginWithApiUseCase(this._repository);

  Future<User> call(String email, String password) {
    return _repository.loginWithApi(email, password);
  }
}
