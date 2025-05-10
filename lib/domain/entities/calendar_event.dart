import 'package:equatable/equatable.dart';

enum EventPriority {
  low,
  medium,
  high,
}

enum EventStatus {
  pending,
  inProgress,
  completed,
  cancelled,
}

class CalendarEvent extends Equatable {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final bool isAllDay;
  final String location;
  final List<String> attendees;
  final EventPriority priority;
  final EventStatus status;
  final String? recurrenceRule;
  final String? reminderId;
  final String creatorId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;
  final String? color;

  const CalendarEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.isAllDay,
    required this.location,
    required this.attendees,
    required this.priority,
    required this.status,
    this.recurrenceRule,
    this.reminderId,
    required this.creatorId,
    required this.createdAt,
    required this.updatedAt,
    required this.tags,
    this.color,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    startTime,
    endTime,
    isAllDay,
    location,
    attendees,
    priority,
    status,
    recurrenceRule,
    reminderId,
    creatorId,
    createdAt,
    updatedAt,
    tags,
    color,
  ];

  CalendarEvent copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    bool? isAllDay,
    String? location,
    List<String>? attendees,
    EventPriority? priority,
    EventStatus? status,
    String? recurrenceRule,
    String? reminderId,
    String? creatorId,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    String? color,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isAllDay: isAllDay ?? this.isAllDay,
      location: location ?? this.location,
      attendees: attendees ?? this.attendees,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      reminderId: reminderId ?? this.reminderId,
      creatorId: creatorId ?? this.creatorId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      color: color ?? this.color,
    );
  }

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      isAllDay: json['is_all_day'] as bool,
      location: json['location'] as String,
      attendees: List<String>.from(json['attendees'] as List),
      priority: EventPriority.values.firstWhere(
        (e) => e.toString() == 'EventPriority.${json['priority']}',
      ),
      status: EventStatus.values.firstWhere(
        (e) => e.toString() == 'EventStatus.${json['status']}',
      ),
      recurrenceRule: json['recurrence_rule'] as String?,
      reminderId: json['reminder_id'] as String?,
      creatorId: json['creator_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      tags: List<String>.from(json['tags'] as List),
      color: json['color'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'is_all_day': isAllDay,
      'location': location,
      'attendees': attendees,
      'priority': priority.toString().split('.').last,
      'status': status.toString().split('.').last,
      'recurrence_rule': recurrenceRule,
      'reminder_id': reminderId,
      'creator_id': creatorId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'tags': tags,
      'color': color,
    };
  }
} 