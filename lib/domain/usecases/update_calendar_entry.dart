import '../entities/calendar_entry.dart';
import '../repositories/calendar_repository.dart';

class UpdateCalendarEntryUseCase {
  final CalendarRepository repository;

  UpdateCalendarEntryUseCase(this.repository);

  Future<void> call(CalendarEntry entry) {
    return repository.updateEntry(entry);
  }
}
