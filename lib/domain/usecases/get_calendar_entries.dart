import '../entities/calendar_entry.dart';
import '../repositories/calendar_repository.dart';

class GetCalendarEntriesUseCase {
  final CalendarRepository repository;

  GetCalendarEntriesUseCase(this.repository);

  Future<List<CalendarEntry>> callByUser(String userId) {
    return repository.getEntriesByUser(userId);
  }

  Future<List<CalendarEntry>> callByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return repository.getEntriesByDateRange(userId, startDate, endDate);
  }
}
