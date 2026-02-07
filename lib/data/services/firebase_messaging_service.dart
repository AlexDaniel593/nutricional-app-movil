import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

/// Servicio para gestionar notificaciones push con Firebase Cloud Messaging
class FirebaseMessagingService {
  static final FirebaseMessagingService instance = FirebaseMessagingService._init();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  
  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  FirebaseMessagingService._init();

  /// Inicializa el servicio de Firebase Messaging
  Future<void> initialize() async {
    // 1. Solicitar permisos de notificaciones
    await _requestPermissions();
    
    // 2. Obtener el token FCM
    await _getToken();
    
    // 3. Configurar manejadores de mensajes
    _configureMessageHandlers();
  }

  /// Solicita permisos para mostrar notificaciones
  Future<void> _requestPermissions() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('Permiso de notificaciones: ${settings.authorizationStatus}');
  }

  /// Obtiene y guarda el token FCM del dispositivo
  Future<void> _getToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      debugPrint('FCM Token: $_fcmToken');
      
      // Aquí puedes enviar el token a tu backend para almacenarlo
      // await _saveTokenToBackend(_fcmToken);
      
    } catch (e) {
      debugPrint('Error al obtener FCM token: $e');
    }

    // Escuchar cambios en el token
    _messaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      debugPrint('FCM Token actualizado: $newToken');
      // Actualizar el token en tu backend
      // await _saveTokenToBackend(newToken);
    });
  }

  /// Configura los manejadores para diferentes estados de la app
  void _configureMessageHandlers() {
    // Nota: Los manejadores de navegación se configurarán desde el widget
    // que tenga acceso al BuildContext
  }

  /// Configura el manejador de mensajes en primer plano
  /// Debe llamarse desde un widget que tenga acceso al BuildContext
  void configureForegroundHandler(
    BuildContext context,
    Function(String title, String body) onNotificationReceived,
  ) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final title = message.notification?.title ?? 'Notificación';
      final body = message.notification?.body ?? '';
      
      debugPrint('Notificación recibida en primer plano: $title - $body');
      
      // Llamar al callback con los datos
      onNotificationReceived(title, body);
      
      // Mostrar diálogo
      _showNotificationDialog(context, title, body);
    });
  }

  /// Configura el manejador cuando la app está en segundo plano y se abre
  void configureBackgroundHandler(
    BuildContext context,
    Function(String title, String body) onNotificationOpened,
  ) {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final title = message.notification?.title ?? 'Notificación';
      final body = message.notification?.body ?? '';
      
      debugPrint('App abierta desde notificación (segundo plano): $title - $body');
      
      // Llamar al callback
      onNotificationOpened(title, body);
    });
  }

  /// Verifica si la app se abrió desde una notificación (app terminada)
  Future<void> checkInitialMessage(
    BuildContext context,
    Function(String title, String body) onNotificationOpened,
  ) async {
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    
    if (initialMessage != null) {
      final title = initialMessage.notification?.title ?? 'Notificación';
      final body = initialMessage.notification?.body ?? '';
      
      debugPrint('App abierta desde notificación (terminada): $title - $body');
      
      // Llamar al callback
      onNotificationOpened(title, body);
    }
  }

  /// Muestra un diálogo con la notificación recibida
  void _showNotificationDialog(BuildContext context, String title, String body) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.notifications_active, color: Colors.green),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          body,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Navegar a página de detalle
              Navigator.pushNamed(
                context,
                '/notification-detail',
                arguments: {'title': title, 'body': body},
              );
            },
            child: Text('Ver detalles'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  /// Suscribe el dispositivo a un tema/topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('Suscrito al tema: $topic');
    } catch (e) {
      debugPrint('Error al suscribirse al tema $topic: $e');
    }
  }

  /// Desuscribe el dispositivo de un tema/topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('Desuscrito del tema: $topic');
    } catch (e) {
      debugPrint('Error al desuscribirse del tema $topic: $e');
    }
  }
}

/// Manejador de mensajes en segundo plano (debe estar en top-level)
/// Se ejecuta cuando la app está completamente cerrada
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Mensaje recibido en segundo plano: ${message.messageId}');
  debugPrint('Título: ${message.notification?.title}');
  debugPrint('Cuerpo: ${message.notification?.body}');
}
