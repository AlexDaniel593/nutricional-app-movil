import '../entities/calendar_entry.dart';

abstract class CalendarRepository {
  Future<CalendarEntry> createEntry(CalendarEntry entry);
  Future<List<CalendarEntry>> getEntriesByUser(String userId);
  Future<List<CalendarEntry>> getEntriesByDateRange(String userId, DateTime startDate, DateTime endDate);
  Future<CalendarEntry> getEntryById(String id);
  Future<void> updateEntry(CalendarEntry entry);
  Future<void> deleteEntry(String id);
  Future<void> syncAllFromCloud(String userId);
}
