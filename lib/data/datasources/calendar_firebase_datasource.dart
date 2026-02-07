import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/calendar_entry.dart';

class CalendarFirebaseDatasource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'calendar';

  /// Crear entrada de calendario
  Future<CalendarEntry> createEntry(CalendarEntry entry) async {
    try {
      final docRef = await _firestore.collection(_collection).add({
        'userId': entry.userId,
        'recipeId': entry.recipeId,
        'recipeTitle': entry.recipeTitle,
        'recipeImageUrl': entry.recipeImageUrl,
        'scheduledDate': Timestamp.fromDate(entry.scheduledDate),
        'mealType': entry.mealType,
        'notificationSent': entry.notificationSent,
        'createdAt': Timestamp.fromDate(entry.createdAt),
      });

      return CalendarEntry(
        id: docRef.id,
        userId: entry.userId,
        recipeId: entry.recipeId,
        recipeTitle: entry.recipeTitle,
        recipeImageUrl: entry.recipeImageUrl,
        scheduledDate: entry.scheduledDate,
        mealType: entry.mealType,
        notificationSent: entry.notificationSent,
        createdAt: entry.createdAt,
      );
    } catch (e) {
      throw Exception('Error al crear entrada de calendario: ${e.toString()}');
    }
  }

  /// Obtener entradas por usuario
  Future<List<CalendarEntry>> getEntriesByUser(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      final entries = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return CalendarEntry(
          id: doc.id,
          userId: data['userId'] ?? '',
          recipeId: data['recipeId'] ?? '',
          recipeTitle: data['recipeTitle'] ?? '',
          recipeImageUrl: data['recipeImageUrl'] ?? '',
          scheduledDate: (data['scheduledDate'] as Timestamp).toDate(),
          mealType: data['mealType'] ?? '',
          notificationSent: data['notificationSent'] ?? false,
          createdAt: (data['createdAt'] as Timestamp).toDate(),
        );
      }).toList();

      entries.sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));
      return entries;
    } catch (e) {
      throw Exception('Error al obtener entradas: ${e.toString()}');
    }
  }

  /// Obtener entradas por rango de fechas
  Future<List<CalendarEntry>> getEntriesByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('scheduledDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('scheduledDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final entries = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return CalendarEntry(
          id: doc.id,
          userId: data['userId'] ?? '',
          recipeId: data['recipeId'] ?? '',
          recipeTitle: data['recipeTitle'] ?? '',
          recipeImageUrl: data['recipeImageUrl'] ?? '',
          scheduledDate: (data['scheduledDate'] as Timestamp).toDate(),
          mealType: data['mealType'] ?? '',
          notificationSent: data['notificationSent'] ?? false,
          createdAt: (data['createdAt'] as Timestamp).toDate(),
        );
      }).toList();

      entries.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
      return entries;
    } catch (e) {
      throw Exception('Error al obtener entradas por rango: ${e.toString()}');
    }
  }

  /// Obtener entrada por ID
  Future<CalendarEntry> getEntryById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (!doc.exists) throw Exception('Entrada no encontrada');

      final data = doc.data()!;
      return CalendarEntry(
        id: doc.id,
        userId: data['userId'] ?? '',
        recipeId: data['recipeId'] ?? '',
        recipeTitle: data['recipeTitle'] ?? '',
        recipeImageUrl: data['recipeImageUrl'] ?? '',
        scheduledDate: (data['scheduledDate'] as Timestamp).toDate(),
        mealType: data['mealType'] ?? '',
        notificationSent: data['notificationSent'] ?? false,
        createdAt: (data['createdAt'] as Timestamp).toDate(),
      );
    } catch (e) {
      throw Exception('Error al obtener entrada: ${e.toString()}');
    }
  }

  /// Actualizar entrada
  Future<void> updateEntry(CalendarEntry entry) async {
    try {
      await _firestore.collection(_collection).doc(entry.id).update({
        'recipeId': entry.recipeId,
        'recipeTitle': entry.recipeTitle,
        'recipeImageUrl': entry.recipeImageUrl,
        'scheduledDate': Timestamp.fromDate(entry.scheduledDate),
        'mealType': entry.mealType,
        'notificationSent': entry.notificationSent,
      });
    } catch (e) {
      throw Exception('Error al actualizar entrada: ${e.toString()}');
    }
  }

  /// Eliminar entrada
  Future<void> deleteEntry(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Error al eliminar entrada: ${e.toString()}');
    }
  }
}
