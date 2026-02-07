import '../../domain/entities/user.dart';
import '../repositories/auth_repository.dart';

class LoginWithGoogleUseCase {
  final AuthRepository _repository;

  LoginWithGoogleUseCase(this._repository);

  Future<User> call() {
    return _repository.loginWithGoogle();
  }
}
