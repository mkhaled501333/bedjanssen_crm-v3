// ignore_for_file: public_member_api_docs

import 'package:mysql1/mysql1.dart';
import 'database_config.dart';

class DatabaseService {
  static MySqlConnection get _connection => DatabaseConfig.connection;

  /// Execute a query and return the results with connection recovery
  static Future<Results> query(
    String sql, {
    List<Object?>? parameters,
    int maxRetries = 2,
    int? userId,
  }) async {
    int retryCount = 0;
    
    // Validate and sanitize parameters to prevent encoding issues
    final sanitizedParams = _sanitizeParameters(parameters ?? []);
    
    while (retryCount <= maxRetries) {
      try {
        // Validate connection before executing query
        if (!await _isConnectionValid()) {
          print('Connection invalid, attempting to reconnect...');
          await DatabaseConfig.reconnect();
        }
        
        // Set user context for audit triggers if userId is provided
        if (userId != null) {
          await _connection.query('SET @current_user_id = ?', [userId.toString()]);
        }
        
        final result = await _connection.query(sql, sanitizedParams);
        
        // Clear user context after query
        if (userId != null) {
          await _connection.query('SET @current_user_id = NULL');
        }
        
        return result;
      } catch (e) {
        print('Database query error (attempt ${retryCount + 1}): $e');
        
        // Clear user context on error
        if (userId != null) {
          try {
            await _connection.query('SET @current_user_id = NULL');
          } catch (clearError) {
            print('Failed to clear user context: $clearError');
          }
        }
        
        // Check for connection-related errors
        if (_isConnectionError(e) && retryCount < maxRetries) {
          print('Attempting to reconnect to database...');
          try {
            await DatabaseConfig.reconnect();
            retryCount++;
            continue;
          } catch (reconnectError) {
            print('Failed to reconnect: $reconnectError');
            if (retryCount == maxRetries) rethrow;
          }
        } else {
          rethrow;
        }
      }
    }
    
    throw Exception('Failed to execute query after $maxRetries retries');
  }

  /// Sanitize parameters to prevent UTF-8 encoding issues
  static List<Object?> _sanitizeParameters(List<Object?> parameters) {
    return parameters.map((param) {
      if (param is String) {
        // Ensure proper UTF-8 encoding and remove invalid characters
        try {
          final bytes = param.codeUnits;
          // Check for valid UTF-8 range
          for (int byte in bytes) {
            if (byte > 0xFFFF) {
              // Replace invalid characters with replacement character
              return param.replaceAll(RegExp(r'[^\u0000-\uFFFF]'), '\uFFFD');
            }
          }
          return param;
        } catch (e) {
          print('Parameter encoding error: $e');
          return param.replaceAll(RegExp(r'[^\u0000-\uFFFF]'), '\uFFFD');
        }
      }
      return param;
    }).toList();
  }

  /// Check if connection is valid
  static Future<bool> _isConnectionValid() async {
    try {
      await _connection.query('SELECT 1');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if the error is connection-related
  static bool _isConnectionError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('socket') ||
           errorString.contains('closed') ||
           errorString.contains('connection') ||
           errorString.contains('timeout') ||
           errorString.contains('broken pipe') ||
           errorString.contains('rangeerror') ||
           errorString.contains('index out of range') ||
           errorString.contains('byteoffset');
  }



  /// Execute a query and return a single row
  static Future<ResultRow?> queryOne(
    String sql, {
    List<Object?>? parameters,
    int? userId,
  }) async {
    final result = await query(sql, parameters: parameters, userId: userId);
    return result.isNotEmpty ? result.first : null;
  }

  /// Execute a query and return multiple rows
  static Future<List<ResultRow>> queryMany(
    String sql, {
    List<Object?>? parameters,
    int? userId,
  }) async {
    final result = await query(sql, parameters: parameters, userId: userId);
    return result.toList();
  }

  /// Execute an insert statement and return the inserted ID
  static Future<int> insert(
    String table,
    Map<String, dynamic> data, {
    int? userId,
  }) async {
    final columns = data.keys.join(', ');
    final placeholders = List.filled(data.length, '?').join(', ');
    
    final sql = 'INSERT INTO $table ($columns) VALUES ($placeholders)';
    final result = await query(sql, parameters: data.values.toList(), userId: userId);
    return result.insertId ?? 0;
  }

  /// Execute an update statement and return the number of affected rows
  static Future<int> update(
    String table,
    Map<String, dynamic> data,
    String whereClause, {
    List<Object?>? whereParameters,
    int? userId,
  }) async {
    final setClause = data.keys.map((key) => '$key = ?').join(', ');
    
    final sql = 'UPDATE $table SET $setClause WHERE $whereClause';
    final parameters = [...data.values, ...?whereParameters];
    
    final result = await query(sql, parameters: parameters, userId: userId);
    return result.affectedRows ?? 0;
  }

  /// Execute a delete statement and return the number of affected rows
  static Future<int> delete(
    String table,
    String whereClause, {
    List<Object?>? parameters,
    int? userId,
  }) async {
    final sql = 'DELETE FROM $table WHERE $whereClause';
    final result = await query(sql, parameters: parameters, userId: userId);
    return result.affectedRows ?? 0;
  }

  /// Check if a table exists
  static Future<bool> tableExists(String tableName) async {
    const sql = '''
      SELECT COUNT(*) as count
      FROM information_schema.tables 
      WHERE table_schema = DATABASE() 
      AND table_name = ?
    ''';
    
    final result = await queryOne(sql, parameters: [tableName]);
    final count = result?['count'] as int? ?? 0;
    return count > 0;
  }

  /// Execute a transaction
  static Future<T> transaction<T>(Future<T> Function() operation, {int? userId}) async {
    await _connection.query('START TRANSACTION');
    
    // Set user context for audit triggers if userId is provided
    if (userId != null) {
      await _connection.query('SET @current_user_id = ?', [userId.toString()]);
    }
    
    try {
      final result = await operation();
      await _connection.query('COMMIT');
      
      // Clear user context after successful transaction
      if (userId != null) {
        await _connection.query('SET @current_user_id = NULL');
      }
      
      return result;
    } catch (e) {
      await _connection.query('ROLLBACK');
      
      // Clear user context on rollback
      if (userId != null) {
        try {
          await _connection.query('SET @current_user_id = NULL');
        } catch (clearError) {
          print('Failed to clear user context on rollback: $clearError');
        }
      }
      
      rethrow;
    }
  }

  /// Get the current database name
  static Future<String?> getCurrentDatabase() async {
    final result = await queryOne('SELECT DATABASE() as db_name');
    return result?['db_name'] as String?;
  }

  /// Execute a prepared statement
  static Future<Results> prepared(
    String sql,
    List<Object?> parameters, {
    int? userId,
  }) async {
    try {
      // Set user context for audit triggers if userId is provided
      if (userId != null) {
        await _connection.query('SET @current_user_id = ?', [userId.toString()]);
      }
      
      final result = await _connection.query(sql, parameters);
      
      // Clear user context after query
      if (userId != null) {
        await _connection.query('SET @current_user_id = NULL');
      }
      
      return result;
    } catch (e) {
      // Clear user context on error
      if (userId != null) {
        try {
          await _connection.query('SET @current_user_id = NULL');
        } catch (clearError) {
          print('Failed to clear user context: $clearError');
        }
      }
      
      print('Prepared statement error: $e');
      rethrow;
    }
  }
}