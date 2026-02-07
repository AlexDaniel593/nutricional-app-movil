import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../../domain/entities/calendar_entry.dart';

/// Servicio para gestionar notificaciones locales
class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  NotificationService._init();

  /// Inicializa el servicio de notificaciones
  Future<void> initialize() async {
    if (_initialized) return;

    // Inicializar zonas horarias
    tz.initializeTimeZones();

    // Configuración para Android
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuración de inicialización
    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  /// Maneja el tap en una notificación
  void _onNotificationTapped(NotificationResponse response) {
    // Aquí puedes manejar la navegación cuando se toca una notificación
    // Por ejemplo, navegar al detalle de la receta
  }

  /// Programa notificaciones para una entrada de calendario
  /// - Una notificación 1 hora antes
  /// - Una notificación en el momento exacto
  Future<void> scheduleNotification(CalendarEntry entry) async {
    if (!_initialized) await initialize();

    final now = DateTime.now();
    
    // Notificación 1 hora antes
    final reminderTime = entry.scheduledDate.subtract(const Duration(hours: 1));
    if (reminderTime.isAfter(now)) {
      const androidDetails = AndroidNotificationDetails(
        'meal_reminders',
        'Recordatorios de Comida',
        channelDescription: 'Notificaciones para recordar tus comidas programadas',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      await _notifications.zonedSchedule(
        entry.id.hashCode, // ID único para notificación de recordatorio
        '🔔 ${_getMealTypeTitle(entry.mealType)} en 1 hora',
        'Recuerda preparar: ${entry.recipeTitle}',
        tz.TZDateTime.from(reminderTime, tz.local),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: entry.id,
      );
    }

    // Notificación en el momento exacto
    if (entry.scheduledDate.isAfter(now)) {
      const androidDetailsNow = AndroidNotificationDetails(
        'meal_now',
        'Hora de Comida',
        channelDescription: 'Notificaciones cuando es hora de comer',
        importance: Importance.max,
        priority: Priority.max,
        showWhen: true,
        playSound: true,
        enableVibration: true,
      );

      const notificationDetailsNow = NotificationDetails(android: androidDetailsNow);

      await _notifications.zonedSchedule(
        '${entry.id}_now'.hashCode, // ID diferente para notificación de ahora
        '⏰ Es hora de ${_getMealTypeTitle(entry.mealType).toLowerCase()}',
        '¡Disfruta tu ${entry.recipeTitle}!',
        tz.TZDateTime.from(entry.scheduledDate, tz.local),
        notificationDetailsNow,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: entry.id,
      );
    }
  }

  /// Cancela todas las notificaciones de una entrada
  Future<void> cancelNotification(String entryId) async {
    await _notifications.cancel(entryId.hashCode); // Notificación 1 hora antes
    await _notifications.cancel('${entryId}_now'.hashCode); // Notificación en el momento
  }

  /// Cancela todas las notificaciones
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Obtiene el título según el tipo de comida
  String _getMealTypeTitle(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return 'Desayuno';
      case 'lunch':
        return 'Almuerzo';
      case 'dinner':
        return 'Cena';
      case 'snack':
        return 'Snack';
      default:
        return 'Comida';
    }
  }

  /// Verifica si las notificaciones están habilitadas
  Future<bool> areNotificationsEnabled() async {
    if (!_initialized) await initialize();
    
    final result = await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.areNotificationsEnabled();
    
    return result ?? false;
  }

  /// Solicita permisos de notificación (Android 13+)
  Future<bool> requestPermissions() async {
    if (!_initialized) await initialize();

    final androidImplementation = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final granted = await androidImplementation.requestNotificationsPermission();
      return granted ?? false;
    }

    return true;
  }
}
