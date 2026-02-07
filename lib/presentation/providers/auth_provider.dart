import 'package:flutter/material.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/login_with_email.dart';
import '../../domain/usecases/register_with_email.dart';
import '../../domain/usecases/login_with_google.dart';
import '../../domain/usecases/login_with_facebook.dart';
import '../../domain/usecases/login_with_api.dart';
import '../../domain/usecases/logout.dart';
import '../../domain/usecases/delete_account.dart';
import '../../data/datasources/auth_firebase_datasource.dart';
import '../../data/datasources/local/database_helper.dart';
import '../../data/datasources/local/session_local_datasource.dart';
import '../../data/datasources/local/user_local_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/services/connectivity_service.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isCheckingSession = true;

  late final LoginWithEmailUseCase _loginWithEmail;
  late final RegisterWithEmailUseCase _registerWithEmail;
  late final LoginWithGoogleUseCase _loginWithGoogle;
  late final LoginWithFacebookUseCase _loginWithFacebook;
  late final LoginWithApiUseCase _loginWithApi;
  late final LogoutUseCase _logout;
  late final DeleteAccountUseCase _deleteAccount;
  late final AuthFirebaseDatasource _datasource;
  late final SessionLocalDatasource _sessionDatasource;
  late final UserLocalDatasource _userLocalDatasource;
  late final ConnectivityService _connectivityService;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get isCheckingSession => _isCheckingSession;

  AuthProvider() {
    _datasource = AuthFirebaseDatasource();
    final repository = AuthRepositoryImpl(_datasource);
    
    // Inicializar datasources locales
    final dbHelper = DatabaseHelper.instance;
    _sessionDatasource = SessionLocalDatasource(dbHelper);
    _userLocalDatasource = UserLocalDatasource(dbHelper);
    _connectivityService = ConnectivityService.instance;
    
    _loginWithEmail = LoginWithEmailUseCase(repository);
    _registerWithEmail = RegisterWithEmailUseCase(repository);
    _loginWithGoogle = LoginWithGoogleUseCase(repository);
    _loginWithFacebook = LoginWithFacebookUseCase(repository);
    _loginWithApi = LoginWithApiUseCase(repository);
    _logout = LogoutUseCase(repository);
    _deleteAccount = DeleteAccountUseCase(repository);
    
    // Verificar sesión guardada
    _checkSavedSession();
  }

  /// Verifica si hay una sesión guardada localmente
  Future<void> _checkSavedSession() async {
    _isCheckingSession = true;
    notifyListeners();

    try {
      // Verificar si hay sesión local
      final hasSession = await _sessionDatasource.hasActiveSession();
      
      if (hasSession) {
        // Verificar si la sesión ha expirado
        final isExpired = await _sessionDatasource.isSessionExpired();
        
        if (isExpired) {
          await _sessionDatasource.closeSession();
          _isCheckingSession = false;
          notifyListeners();
          return;
        }

        // Obtener usuario de la sesión
        final savedUser = await _sessionDatasource.getActiveSession();
        
        if (savedUser != null) {
          _currentUser = savedUser;
          // Si hay internet, validar con Firebase
          if (_connectivityService.isConnected) {
            _datasource.getCurrentUser();
          }
        }
      } else {
        // No hay sesión local, verificar Firebase
        _currentUser = _datasource.getCurrentUser();
        if (_currentUser != null) {
          // Guardar sesión de Firebase en local
          await _sessionDatasource.saveActiveSession(_currentUser!);
          await _userLocalDatasource.saveUser(_currentUser!);
        }
      }
    } catch (e) {
      _errorMessage = 'Error al verificar sesión: $e';
    } finally {
      _isCheckingSession = false;
      notifyListeners();
    }

    // Escuchar cambios en el estado de autenticación de Firebase
    _datasource.authStateChanges().listen((user) async {
      if (user != null && user.id != _currentUser?.id) {
        _currentUser = user;
        await _sessionDatasource.saveActiveSession(user);
        await _userLocalDatasource.saveUser(user);
        notifyListeners();
      } else if (user == null && _currentUser != null) {
        // Firebase cerró sesión
        _currentUser = null;
        await _sessionDatasource.closeSession();
        notifyListeners();
      }
    });
  }

  Future<void> loginWithEmail(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _loginWithEmail(email, password);
      
      // Guardar sesión localmente
      if (_currentUser != null) {
        await _sessionDatasource.saveActiveSession(_currentUser!);
        await _userLocalDatasource.saveUser(_currentUser!);
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> registerWithEmail(String email, String password, String displayName) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _registerWithEmail(email, password, displayName);
      
      // Guardar sesión localmente
      if (_currentUser != null) {
        await _sessionDatasource.saveActiveSession(_currentUser!);
        await _userLocalDatasource.saveUser(_currentUser!);
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loginWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _loginWithGoogle();
      
      // Guardar sesión localmente
      if (_currentUser != null) {
        await _sessionDatasource.saveActiveSession(_currentUser!);
        await _userLocalDatasource.saveUser(_currentUser!);
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loginWithFacebook() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _loginWithFacebook();
      
      // Guardar sesión localmente
      if (_currentUser != null) {
        await _sessionDatasource.saveActiveSession(_currentUser!);
        await _userLocalDatasource.saveUser(_currentUser!);
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loginWithApi(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _loginWithApi(email, password);
      
      // Guardar sesión localmente
      if (_currentUser != null) {
        await _sessionDatasource.saveActiveSession(_currentUser!);
        await _userLocalDatasource.saveUser(_currentUser!);
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _logout();
      
      // Limpiar sesión local
      await _sessionDatasource.closeSession();
      
      _currentUser = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteAccount() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _deleteAccount();
      
      // Limpiar sesión local
      await _sessionDatasource.closeSession();
      
      _currentUser = null;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Login unificado: intenta primero con API externa, luego con Firebase
  Future<void> loginUnified(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Intentar primero con API externa
        _currentUser = await _loginWithApi(email, password);
        
        if (_currentUser != null) {
          await _sessionDatasource.saveActiveSession(_currentUser!);
          await _userLocalDatasource.saveUser(_currentUser!);
          return;
        }


      // 2. Si la API falla, intentar con Firebase
      try {
        _currentUser = await _loginWithEmail(email, password);
        
        if (_currentUser != null) {
          await _sessionDatasource.saveActiveSession(_currentUser!);
          await _userLocalDatasource.saveUser(_currentUser!);
        }
      } catch (firebaseError) {
        throw Exception('No se pudo iniciar sesión. Verifica tus credenciales.');
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
