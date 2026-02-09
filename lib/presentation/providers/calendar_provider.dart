import 'package:flutter/material.dart';
import '../../domain/entities/calendar_entry.dart';
import '../../domain/usecases/create_calendar_entry.dart';
import '../../domain/usecases/get_calendar_entries.dart';
import '../../domain/usecases/update_calendar_entry.dart';
import '../../domain/usecases/delete_calendar_entry.dart';
import '../../data/datasources/calendar_firebase_datasource.dart';
import '../../data/datasources/local/database_helper.dart';
import '../../data/datasources/local/calendar_local_datasource.dart';
import '../../data/repositories/calendar_repository_impl.dart';
import '../../data/services/connectivity_service.dart';
import '../../data/services/notification_service.dart';

class CalendarProvider with ChangeNotifier {
  List<CalendarEntry> _entries = [];
  bool _isLoading = false;
  String? _errorMessage;
  DateTime _selectedWeekStart = _getWeekStart(DateTime.now());

  late final CreateCalendarEntryUseCase _createEntry;
  late final GetCalendarEntriesUseCase _getEntries;
  late final UpdateCalendarEntryUseCase _updateEntry;
  late final DeleteCalendarEntryUseCase _deleteEntry;
  late final NotificationService _notificationService;
  late final CalendarRepositoryImpl _repository;
  bool _hasInitialSynced = false;

  List<CalendarEntry> get entries => _entries;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime get selectedWeekStart => _selectedWeekStart;

  CalendarProvider() {
    // Inicializar servicios
    final connectivityService = ConnectivityService.instance;
    final dbHelper = DatabaseHelper.instance;
    final localDatasource = CalendarLocalDatasource(dbHelper);
    final remoteDatasource = CalendarFirebaseDatasource();
    
    _repository = CalendarRepositoryImpl(
      remoteDatasource,
      localDatasource,
      connectivityService,
    );
    
    _notificationService = NotificationService.instance;
    
    _createEntry = CreateCalendarEntryUseCase(_repository);
    _getEntries = GetCalendarEntriesUseCase(_repository);
    _updateEntry = UpdateCalendarEntryUseCase(_repository);
    _deleteEntry = DeleteCalendarEntryUseCase(_repository);

    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
    await _notificationService.requestPermissions();
  }

  /// Obtiene el inicio de la semana (lunes)
  static DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: weekday - 1));
  }

  /// Carga las entradas de una semana específica
  Future<void> loadWeekEntries(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Sincronizar todos los datos de Firebase la primera vez
      if (!_hasInitialSynced) {
        await _repository.syncAllFromCloud(userId);
        _hasInitialSynced = true;
      }
      
      final weekEnd = _selectedWeekStart.add(const Duration(days: 7));
      _entries = await _getEntries.callByDateRange(userId, _selectedWeekStart, weekEnd);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cambia a la semana anterior
  Future<void> previousWeek(String userId) async {
    _selectedWeekStart = _selectedWeekStart.subtract(const Duration(days: 7));
    await loadWeekEntries(userId);
  }

  /// Cambia a la semana siguiente
  Future<void> nextWeek(String userId) async {
    _selectedWeekStart = _selectedWeekStart.add(const Duration(days: 7));
    await loadWeekEntries(userId);
  }

  /// Cambia a la semana actual
  Future<void> goToCurrentWeek(String userId) async {
    _selectedWeekStart = _getWeekStart(DateTime.now());
    await loadWeekEntries(userId);
  }

  /// Obtiene entradas para un día específico
  List<CalendarEntry> getEntriesForDay(DateTime day) {
    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = DateTime(day.year, day.month, day.day, 23, 59, 59);
    
    return _entries.where((entry) {
      return entry.scheduledDate.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
             entry.scheduledDate.isBefore(endOfDay.add(const Duration(seconds: 1)));
    }).toList();
  }

  /// Obtiene entradas para un día y tipo de comida específico
  CalendarEntry? getEntryForDayAndMeal(DateTime day, String mealType) {
    final dayEntries = getEntriesForDay(day);
    try {
      return dayEntries.firstWhere((entry) => entry.mealType == mealType);
    } catch (e) {
      return null;
    }
  }

  /// Agrega una nueva entrada al calendario
  Future<void> addEntry({
    required String userId,
    required String recipeId,
    required String recipeTitle,
    required String recipeImageUrl,
    required DateTime scheduledDate,
    required String mealType,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final entry = CalendarEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        recipeId: recipeId,
        recipeTitle: recipeTitle,
        recipeImageUrl: recipeImageUrl,
        scheduledDate: scheduledDate,
        mealType: mealType,
        notificationSent: false,
        createdAt: DateTime.now(),
      );

      final newEntry = await _createEntry(entry);
      
      // Programar notificación
      await _notificationService.scheduleNotification(newEntry);
      
      // Recargar entradas si está en la semana actual
      if (_isInCurrentWeek(scheduledDate)) {
        await loadWeekEntries(userId);
      }
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Actualiza una entrada existente
  Future<void> modifyEntry({
    required CalendarEntry entry,
    required String userId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _updateEntry(entry);
      
      // Reprogramar notificación
      await _notificationService.cancelNotification(entry.id);
      await _notificationService.scheduleNotification(entry);
      
      // Recargar entradas
      await loadWeekEntries(userId);
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Elimina una entrada
  Future<void> removeEntry(String id, String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Eliminar (esto ahora elimina primero de Firebase)
      await _deleteEntry(id);
      
      // Cancelar notificación
      await _notificationService.cancelNotification(id);
      
      // Actualizar la lista local inmediatamente removiendo la entrada
      _entries.removeWhere((entry) => entry.id == id);
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Verifica si una fecha está en la semana seleccionada
  bool _isInCurrentWeek(DateTime date) {
    final weekEnd = _selectedWeekStart.add(const Duration(days: 7));
    return date.isAfter(_selectedWeekStart.subtract(const Duration(seconds: 1))) &&
           date.isBefore(weekEnd);
  }

  /// Obtiene los días de la semana actual
  List<DateTime> getWeekDays() {
    return List.generate(7, (index) => _selectedWeekStart.add(Duration(days: index)));
  }

  /// Fuerza una sincronización completa desde Firebase
  Future<void> syncFromCloud(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.syncAllFromCloud(userId);
      _hasInitialSynced = true;
      // Recargar la semana actual desde la base de datos local después de sincronizar
      final weekEnd = _selectedWeekStart.add(const Duration(days: 7));
      _entries = await _getEntries.callByDateRange(userId, _selectedWeekStart, weekEnd);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
