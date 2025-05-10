import 'package:oxicloud_desktop/core/network/api_client.dart';
import 'package:oxicloud_desktop/domain/entities/calendar_event.dart';
import 'package:oxicloud_desktop/domain/repositories/calendar_repository.dart';

class ApiCalendarRepository implements CalendarRepository {
  final ApiClient _apiClient;

  ApiCalendarRepository(this._apiClient);

  @override
  Future<List<CalendarEvent>> getEvents(DateTime start, DateTime end) async {
    final response = await _apiClient.get('/calendar/events', queryParameters: {
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
    });

    final List<dynamic> events = response.data['events'] as List;
    return events.map((event) => CalendarEvent.fromJson(event)).toList();
  }

  @override
  Future<CalendarEvent> getEvent(String eventId) async {
    final response = await _apiClient.get('/calendar/events/$eventId');
    return CalendarEvent.fromJson(response.data);
  }

  @override
  Future<CalendarEvent> createEvent(CalendarEvent event) async {
    final response = await _apiClient.post(
      '/calendar/events',
      data: event.toJson(),
    );
    return CalendarEvent.fromJson(response.data);
  }

  @override
  Future<CalendarEvent> updateEvent(CalendarEvent event) async {
    final response = await _apiClient.put(
      '/calendar/events/${event.id}',
      data: event.toJson(),
    );
    return CalendarEvent.fromJson(response.data);
  }

  @override
  Future<void> deleteEvent(String eventId) async {
    await _apiClient.delete('/calendar/events/$eventId');
  }

  @override
  Future<List<CalendarEvent>> getRecurringEvents(String recurrenceRule) async {
    final response = await _apiClient.get('/calendar/events/recurring', queryParameters: {
      'rule': recurrenceRule,
    });

    final List<dynamic> events = response.data['events'] as List;
    return events.map((event) => CalendarEvent.fromJson(event)).toList();
  }

  @override
  Future<List<CalendarEvent>> getEventsByTag(String tag) async {
    final response = await _apiClient.get('/calendar/events/tag/$tag');
    final List<dynamic> events = response.data['events'] as List;
    return events.map((event) => CalendarEvent.fromJson(event)).toList();
  }

  @override
  Future<List<CalendarEvent>> getEventsByAttendee(String userId) async {
    final response = await _apiClient.get('/calendar/events/attendee/$userId');
    final List<dynamic> events = response.data['events'] as List;
    return events.map((event) => CalendarEvent.fromJson(event)).toList();
  }

  @override
  Future<List<CalendarEvent>> getEventsByLocation(String location) async {
    final response = await _apiClient.get('/calendar/events/location', queryParameters: {
      'location': location,
    });
    final List<dynamic> events = response.data['events'] as List;
    return events.map((event) => CalendarEvent.fromJson(event)).toList();
  }

  @override
  Future<List<CalendarEvent>> getEventsByStatus(EventStatus status) async {
    final response = await _apiClient.get('/calendar/events/status', queryParameters: {
      'status': status.toString().split('.').last,
    });
    final List<dynamic> events = response.data['events'] as List;
    return events.map((event) => CalendarEvent.fromJson(event)).toList();
  }

  @override
  Future<List<CalendarEvent>> getEventsByPriority(EventPriority priority) async {
    final response = await _apiClient.get('/calendar/events/priority', queryParameters: {
      'priority': priority.toString().split('.').last,
    });
    final List<dynamic> events = response.data['events'] as List;
    return events.map((event) => CalendarEvent.fromJson(event)).toList();
  }

  @override
  Future<List<CalendarEvent>> searchEvents(String query) async {
    final response = await _apiClient.get('/calendar/events/search', queryParameters: {
      'query': query,
    });
    final List<dynamic> events = response.data['events'] as List;
    return events.map((event) => CalendarEvent.fromJson(event)).toList();
  }

  @override
  Future<List<CalendarEvent>> getUpcomingEvents(int limit) async {
    final response = await _apiClient.get('/calendar/events/upcoming', queryParameters: {
      'limit': limit,
    });
    final List<dynamic> events = response.data['events'] as List;
    return events.map((event) => CalendarEvent.fromJson(event)).toList();
  }

  @override
  Future<List<CalendarEvent>> getOverdueEvents() async {
    final response = await _apiClient.get('/calendar/events/overdue');
    final List<dynamic> events = response.data['events'] as List;
    return events.map((event) => CalendarEvent.fromJson(event)).toList();
  }

  @override
  Future<List<CalendarEvent>> getTodayEvents() async {
    final response = await _apiClient.get('/calendar/events/today');
    final List<dynamic> events = response.data['events'] as List;
    return events.map((event) => CalendarEvent.fromJson(event)).toList();
  }

  @override
  Future<List<CalendarEvent>> getWeekEvents() async {
    final response = await _apiClient.get('/calendar/events/week');
    final List<dynamic> events = response.data['events'] as List;
    return events.map((event) => CalendarEvent.fromJson(event)).toList();
  }

  @override
  Future<List<CalendarEvent>> getMonthEvents() async {
    final response = await _apiClient.get('/calendar/events/month');
    final List<dynamic> events = response.data['events'] as List;
    return events.map((event) => CalendarEvent.fromJson(event)).toList();
  }
} 