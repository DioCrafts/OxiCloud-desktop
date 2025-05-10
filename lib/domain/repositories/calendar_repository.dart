import 'package:oxicloud_desktop/domain/entities/calendar_event.dart';

abstract class CalendarRepository {
  /// Obtiene eventos en un rango de fechas
  Future<List<CalendarEvent>> getEvents(DateTime start, DateTime end);
  
  /// Obtiene un evento por su ID
  Future<CalendarEvent> getEvent(String eventId);
  
  /// Crea un nuevo evento
  Future<CalendarEvent> createEvent(CalendarEvent event);
  
  /// Actualiza un evento existente
  Future<CalendarEvent> updateEvent(CalendarEvent event);
  
  /// Elimina un evento
  Future<void> deleteEvent(String eventId);
  
  /// Obtiene eventos recurrentes
  Future<List<CalendarEvent>> getRecurringEvents(String recurrenceRule);
  
  /// Obtiene eventos por etiqueta
  Future<List<CalendarEvent>> getEventsByTag(String tag);
  
  /// Obtiene eventos por asistente
  Future<List<CalendarEvent>> getEventsByAttendee(String userId);
  
  /// Obtiene eventos por ubicación
  Future<List<CalendarEvent>> getEventsByLocation(String location);
  
  /// Obtiene eventos por estado
  Future<List<CalendarEvent>> getEventsByStatus(EventStatus status);
  
  /// Obtiene eventos por prioridad
  Future<List<CalendarEvent>> getEventsByPriority(EventPriority priority);
  
  /// Busca eventos
  Future<List<CalendarEvent>> searchEvents(String query);
  
  /// Obtiene eventos próximos
  Future<List<CalendarEvent>> getUpcomingEvents(int limit);
  
  /// Obtiene eventos vencidos
  Future<List<CalendarEvent>> getOverdueEvents();
  
  /// Obtiene eventos del día
  Future<List<CalendarEvent>> getTodayEvents();
  
  /// Obtiene eventos de la semana
  Future<List<CalendarEvent>> getWeekEvents();
  
  /// Obtiene eventos del mes
  Future<List<CalendarEvent>> getMonthEvents();
} 