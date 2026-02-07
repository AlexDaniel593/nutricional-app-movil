import '../../domain/entities/user.dart';
import '../repositories/auth_repository.dart';

class LoginWithFacebookUseCase {
  final AuthRepository _repository;

  LoginWithFacebookUseCase(this._repository);

  Future<User> call() {
    return _repository.loginWithFacebook();
  }
}
