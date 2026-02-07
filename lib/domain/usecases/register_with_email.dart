import '../../domain/entities/user.dart';
import '../repositories/auth_repository.dart';

class RegisterWithEmailUseCase {
  final AuthRepository _repository;

  RegisterWithEmailUseCase(this._repository);

  Future<User> call(String email, String password, String displayName) {
    return _repository.registerWithEmail(email, password, displayName);
  }
}
