import '../repositories/calendar_repository.dart';

class DeleteCalendarEntryUseCase {
  final CalendarRepository repository;

  DeleteCalendarEntryUseCase(this.repository);

  Future<void> call(String id) {
    return repository.deleteEntry(id);
  }
}
