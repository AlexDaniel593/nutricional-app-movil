import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Servicio para monitorear la conectividad a internet
class ConnectivityService {
  static final ConnectivityService instance = ConnectivityService._init();
  
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionStatusController = StreamController<bool>.broadcast();
  
  bool _isConnected = false;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  ConnectivityService._init();

  /// Stream que notifica cambios en la conectividad
  Stream<bool> get connectionStream => _connectionStatusController.stream;

  /// Estado actual de la conexión
  bool get isConnected => _isConnected;

  /// Inicializa el monitoreo de conectividad
  Future<void> initialize() async {
    // Verificar estado inicial
    _isConnected = await checkConnection();
    
    // Escuchar cambios de conectividad
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) async {
      final hasConnection = _hasInternetConnection(result);
      if (_isConnected != hasConnection) {
        _isConnected = hasConnection;
        _connectionStatusController.add(_isConnected);
      }
    });
  }

  /// Verifica si hay conexión a internet
  Future<bool> checkConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return _hasInternetConnection(result);
    } catch (e) {
      return false;
    }
  }

  /// Verifica si el resultado de conectividad indica conexión real
  bool _hasInternetConnection(ConnectivityResult result) {
    // Si no hay conectividad, retorna false
    if (result == ConnectivityResult.none) {
      return false;
    }

    // Si hay wifi, mobile o ethernet, asumir que hay conexión
    if (result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.ethernet) {
      return true;
    }

    return false;
  }

  /// Espera hasta que haya conexión (útil para sincronización)
  Future<void> waitForConnection({Duration timeout = const Duration(seconds: 30)}) async {
    if (_isConnected) return;

    final completer = Completer<void>();
    StreamSubscription? subscription;

    subscription = connectionStream.listen((connected) {
      if (connected && !completer.isCompleted) {
        completer.complete();
        subscription?.cancel();
      }
    });

    // Timeout
    Future.delayed(timeout, () {
      if (!completer.isCompleted) {
        subscription?.cancel();
        completer.completeError(TimeoutException('No se pudo establecer conexión'));
      }
    });

    return completer.future;
  }

  /// Libera recursos
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectionStatusController.close();
  }
}
