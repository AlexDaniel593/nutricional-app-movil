import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../../domain/entities/user.dart' as entities;

class AuthFirebaseDatasource {
  final auth.FirebaseAuth _firebaseAuth = auth.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

  // Login con email y contraseña
  Future<entities.User> loginWithEmail(String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final user = userCredential.user;
      if (user == null) throw Exception('Usuario no encontrado');
      
      return entities.User(
        id: user.uid,
        username: user.displayName ?? user.email ?? 'Usuario',
        email: user.email ?? '',
      );
    } catch (e) {
      throw Exception('Error al iniciar sesión');
    }
  }

  // Registro con email y contraseña
  Future<entities.User> registerWithEmail(String email, String password, String displayName) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final user = userCredential.user;
      if (user == null) throw Exception('Error al crear usuario');
      
      // Actualizar el nombre de usuario
      await user.updateDisplayName(displayName);
      
      return entities.User(
        id: user.uid,
        username: displayName,
        email: user.email ?? '',
      );
    } catch (e) {
      throw Exception('Error al registrar usuario');
    }
  }

  // Login con Google
  Future<entities.User> loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw Exception('Login cancelado');

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) throw Exception('Usuario no encontrado');

      return entities.User(
        id: user.uid,
        username: user.displayName ?? user.email ?? 'Usuario',
        email: user.email ?? '',
      );
    } catch (e) {
      throw Exception('Error al iniciar sesión con Google');
    }
  }

  // Login con Facebook
  Future<entities.User> loginWithFacebook() async {
    try {
      // Solicitar public_profile y email
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['public_profile', 'email'],
      );
      
      if (result.status != LoginStatus.success) {
        throw Exception('Login con Facebook cancelado');
      }

      final auth.OAuthCredential facebookAuthCredential =
          auth.FacebookAuthProvider.credential(result.accessToken!.tokenString);

      final userCredential = await _firebaseAuth.signInWithCredential(facebookAuthCredential);
      final user = userCredential.user;
      if (user == null) throw Exception('Usuario no encontrado');

      return entities.User(
        id: user.uid,
        username: user.displayName ?? user.email ?? 'Usuario',
        email: user.email ?? '',
      );
    } catch (e) {
      throw Exception('Error al iniciar sesión con Facebook');
    }
  }

  // Cerrar sesión
  Future<void> logout() async {
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
    await FacebookAuth.instance.logOut();
  }

  // Eliminar cuenta de usuario
  Future<void> deleteAccount() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception('No hay usuario autenticado');
    
    await user.delete();
    await _googleSignIn.signOut();
    await FacebookAuth.instance.logOut();
  }

  // Obtener usuario actual
  entities.User? getCurrentUser() {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;

    return entities.User(
      id: user.uid,
      username: user.displayName ?? user.email ?? 'Usuario',
      email: user.email ?? '',
    );
  }

  // Stream del estado de autenticación
  Stream<entities.User?> authStateChanges() {
    return _firebaseAuth.authStateChanges().map((user) {
      if (user == null) return null;
      return entities.User(
        id: user.uid,
        username: user.displayName ?? user.email ?? 'Usuario',
        email: user.email ?? '',
      );
    });
  }
}
