import '../entities/calendar_entry.dart';
import '../repositories/calendar_repository.dart';

class CreateCalendarEntryUseCase {
  final CalendarRepository repository;

  CreateCalendarEntryUseCase(this.repository);

  Future<CalendarEntry> call(CalendarEntry entry) {
    return repository.createEntry(entry);
  }
}
