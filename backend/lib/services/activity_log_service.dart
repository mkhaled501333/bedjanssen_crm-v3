import 'dart:convert';
import 'package:janssencrm_backend/database/database_service.dart';
import 'package:janssencrm_backend/models/activity_log.dart';
import 'package:janssencrm_backend/models/entity.dart';
import 'package:janssencrm_backend/models/activity.dart';
import 'package:janssencrm_backend/services/reports/tickets_utils/data_transformer.dart';

class ActivityLogService {
  /// Log an activity for a specific entity record
  static Future<void> log({
    required int entityId,
    required int recordId,
    required int activityId,
    required int userId,
    Map<String, dynamic>? details,
  }) async {
    try {
      await DatabaseService.query(
        '''
        INSERT INTO activity_logs (entity_id, record_id, activity_id, user_id, details, created_at)
        VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
        ''',
        parameters: [
          entityId,
          recordId,
          activityId,
          userId,
          details != null ? json.encode(details) : null,
        ],
      );
    } catch (e) {
      print('Error logging activity: $e');
      rethrow;
    }
  }

  /// Log an activity by entity and activity names (convenience method)
  static Future<void> logByNames({
    required String entityName,
    required int recordId,
    required String activityName,
    required int userId,
    Map<String, dynamic>? details,
  }) async {
    try {
      // Get entity ID
      final entityResult = await DatabaseService.queryOne(
        'SELECT id FROM entities WHERE name = ?',
        parameters: [entityName],
      );
      
      if (entityResult == null) {
        throw Exception('Entity not found: $entityName');
      }
      
      // Get activity ID
      final activityResult = await DatabaseService.queryOne(
        'SELECT id FROM activities WHERE name = ?',
        parameters: [activityName],
      );
      
      if (activityResult == null) {
        throw Exception('Activity not found: $activityName');
      }
      
      await log(
        entityId: entityResult['id'] as int,
        recordId: recordId,
        activityId: activityResult['id'] as int,
        userId: userId,
        details: details,
      );
    } catch (e) {
      print('Error logging activity by names: $e');
      rethrow;
    }
  }

  /// Retrieve activity logs with filtering options
  static Future<List<ActivityLog>> getActivityLogs({
    int? entityId,
    int? recordId,
    int? userId,
    int? activityId,
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
    int? offset,
  }) async {
    try {
      final conditions = <String>[];
      final parameters = <dynamic>[];
      
      if (entityId != null) {
        conditions.add('al.entity_id = ?');
        parameters.add(entityId);
      }
      
      if (recordId != null) {
        conditions.add('al.record_id = ?');
        parameters.add(recordId);
      }
      
      if (userId != null) {
        conditions.add('al.user_id = ?');
        parameters.add(userId);
      }
      
      if (activityId != null) {
        conditions.add('al.activity_id = ?');
        parameters.add(activityId);
      }
      
      if (fromDate != null) {
        conditions.add('al.created_at >= ?');
        parameters.add(fromDate.toIso8601String());
      }
      
      if (toDate != null) {
        conditions.add('al.created_at <= ?');
        parameters.add(toDate.toIso8601String());
      }
      
      final whereClause = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';
      final limitClause = limit != null ? 'LIMIT $limit' : '';
      final offsetClause = offset != null ? 'OFFSET $offset' : '';
      
      final query = '''
        SELECT al.* FROM activity_logs al
        $whereClause
        ORDER BY al.created_at DESC
        $limitClause $offsetClause
      ''';
      
      final results = await DatabaseService.queryMany(query, parameters: parameters);
      
      return results.map((row) => ActivityLog.fromMap(row.fields)).toList();
    } catch (e) {
      print('Error retrieving activity logs: $e');
      rethrow;
    }
  }

  /// Get detailed activity logs with entity, activity, and user information
  static Future<List<Map<String, dynamic>>> getDetailedActivityLogs({
    int? entityId,
    int? recordId,
    int? userId,
    int? activityId,
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
    int? offset,
  }) async {
    try {
      final conditions = <String>[];
      final parameters = <dynamic>[];
      
      if (entityId != null) {
        conditions.add('al.entity_id = ?');
        parameters.add(entityId);
      }
      
      if (recordId != null) {
        conditions.add('al.record_id = ?');
        parameters.add(recordId);
      }
      
      if (userId != null) {
        conditions.add('al.user_id = ?');
        parameters.add(userId);
      }
      
      if (activityId != null) {
        conditions.add('al.activity_id = ?');
        parameters.add(activityId);
      }
      
      if (fromDate != null) {
        conditions.add('al.created_at >= ?');
        parameters.add(fromDate.toIso8601String());
      }
      
      if (toDate != null) {
        conditions.add('al.created_at <= ?');
        parameters.add(toDate.toIso8601String());
      }
      
      final whereClause = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';
      final limitClause = limit != null ? 'LIMIT $limit' : '';
      final offsetClause = offset != null ? 'OFFSET $offset' : '';
      
      final query = '''
        SELECT 
          al.*,
          e.name as entity_name,
          a.name as activity_name,
          a.description as activity_description,
          u.username as username
        FROM activity_logs al
        LEFT JOIN entities e ON al.entity_id = e.id
        LEFT JOIN activities a ON al.activity_id = a.id
        LEFT JOIN users u ON al.user_id = u.id
        $whereClause
        ORDER BY al.created_at DESC
        $limitClause $offsetClause
      ''';
      
      final results = await DatabaseService.queryMany(query, parameters: parameters);
      
      return results.map((row) {
        final activityLog = ActivityLog.fromMap(row.fields);
        return {
          ...activityLog.toMap(),
          'entity_name': DataTransformer.convertFromBlob(row['entity_name']),
          'activity_name': DataTransformer.convertFromBlob(row['activity_name']),
          'activity_description': DataTransformer.convertFromBlob(row['activity_description']),
          'username': DataTransformer.convertFromBlob(row['username']),
        };
      }).toList();
    } catch (e) {
      print('Error retrieving detailed activity logs: $e');
      rethrow;
    }
  }

  /// Get all entities
  static Future<List<Entity>> getEntities() async {
    try {
      final results = await DatabaseService.queryMany(
        'SELECT * FROM entities ORDER BY name',
      );
      
      return results.map((row) => Entity.fromMap(row.fields)).toList();
    } catch (e) {
      print('Error retrieving entities: $e');
      rethrow;
    }
  }

  /// Get all activities
  static Future<List<Activity>> getActivities() async {
    try {
      final results = await DatabaseService.queryMany(
        'SELECT * FROM activities ORDER BY name',
      );
      
      return results.map((row) => Activity.fromMap(row.fields)).toList();
    } catch (e) {
      print('Error retrieving activities: $e');
      rethrow;
    }
  }

  /// Create or get entity by name
  static Future<int> ensureEntity(String entityName) async {
    try {
      // Try to get existing entity
      final existing = await DatabaseService.queryOne(
        'SELECT id FROM entities WHERE name = ?',
        parameters: [entityName],
      );
      
      if (existing != null) {
        return existing['id'] as int;
      }
      
      // Create new entity
      final result = await DatabaseService.query(
        'INSERT INTO entities (name) VALUES (?)',
        parameters: [entityName],
      );
      
      return result.insertId!;
    } catch (e) {
      print('Error ensuring entity: $e');
      rethrow;
    }
  }

  /// Create or get activity by name
  static Future<int> ensureActivity(String activityName, {String? description}) async {
    try {
      // Try to get existing activity
      final existing = await DatabaseService.queryOne(
        'SELECT id FROM activities WHERE name = ?',
        parameters: [activityName],
      );
      
      if (existing != null) {
        return existing['id'] as int;
      }
      
      // Create new activity
      final result = await DatabaseService.query(
        'INSERT INTO activities (name, description, created_at) VALUES (?, ?, CURRENT_TIMESTAMP)',
        parameters: [activityName, description],
      );
      
      return result.insertId!;
    } catch (e) {
      print('Error ensuring activity: $e');
      rethrow;
    }
  }

  /// Initialize default entities and activities




}