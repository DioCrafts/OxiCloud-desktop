import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oxicloud_desktop/domain/entities/calendar_event.dart';
import 'package:oxicloud_desktop/domain/repositories/calendar_repository.dart';

final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  throw UnimplementedError('Debe ser inicializado con una instancia de ApiCalendarRepository');
});

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final calendarEventsProvider = StateNotifierProvider<CalendarNotifier, AsyncValue<List<CalendarEvent>>>((ref) {
  final repository = ref.watch(calendarRepositoryProvider);
  final selectedDate = ref.watch(selectedDateProvider);
  return CalendarNotifier(repository, selectedDate);
});

class CalendarNotifier extends StateNotifier<AsyncValue<List<CalendarEvent>>> {
  final CalendarRepository _repository;
  final DateTime _selectedDate;

  CalendarNotifier(this._repository, this._selectedDate) : super(const AsyncValue.loading()) {
    loadEvents();
  }

  Future<void> loadEvents() async {
    state = const AsyncValue.loading();
    try {
      final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      final events = await _repository.getEvents(startOfDay, endOfDay);
      state = AsyncValue.data(events);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> createEvent(CalendarEvent event) async {
    try {
      await _repository.createEvent(event);
      await loadEvents();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateEvent(CalendarEvent event) async {
    try {
      await _repository.updateEvent(event);
      await loadEvents();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      await _repository.deleteEvent(eventId);
      await loadEvents();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<List<CalendarEvent>> getUpcomingEvents(int limit) async {
    try {
      return await _repository.getUpcomingEvents(limit);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<CalendarEvent>> getTodayEvents() async {
    try {
      return await _repository.getTodayEvents();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<CalendarEvent>> getWeekEvents() async {
    try {
      return await _repository.getWeekEvents();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<CalendarEvent>> getMonthEvents() async {
    try {
      return await _repository.getMonthEvents();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<CalendarEvent>> searchEvents(String query) async {
    try {
      return await _repository.searchEvents(query);
    } catch (e) {
      rethrow;
    }
  }
} 