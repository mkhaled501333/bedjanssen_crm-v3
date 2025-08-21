import 'dart:convert';

class ActivityLog {
  final int? id;
  final int entityId;
  final int recordId;
  final int activityId;
  final int userId;
  final Map<String, dynamic>? details;
  final DateTime createdAt;

  ActivityLog({
    this.id,
    required this.entityId,
    required this.recordId,
    required this.activityId,
    required this.userId,
    this.details,
    required this.createdAt,
  });

  factory ActivityLog.fromMap(Map<String, dynamic> map) {
    return ActivityLog(
      id: map['id'] as int?,
      entityId: map['entity_id'] as int,
      recordId: map['record_id'] as int,
      activityId: map['activity_id'] as int,
      userId: map['user_id'] as int,
      details: map['details'] != null 
          ? json.decode(map['details'].toString()) as Map<String, dynamic>
          : null,
      createdAt: map['created_at'] is DateTime 
          ? map['created_at'] as DateTime
          : DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entity_id': entityId,
      'record_id': recordId,
      'activity_id': activityId,
      'user_id': userId,
      'details': details != null ? json.encode(details) : null,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'ActivityLog{id: $id, entityId: $entityId, recordId: $recordId, activityId: $activityId, userId: $userId, details: $details, createdAt: $createdAt}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ActivityLog &&
        other.id == id &&
        other.entityId == entityId &&
        other.recordId == recordId &&
        other.activityId == activityId &&
        other.userId == userId &&
        other.details == details &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        entityId.hashCode ^
        recordId.hashCode ^
        activityId.hashCode ^
        userId.hashCode ^
        details.hashCode ^
        createdAt.hashCode;
  }
}