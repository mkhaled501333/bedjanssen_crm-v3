import 'package:mysql1/mysql1.dart';
import '../database_service.dart';

/// Add printing_notes column to tickets table if it doesn't exist
Future<void> addPrintingNotesColumn(MySqlConnection conn) async {
  print('Checking if printing_notes column exists in tickets table...');
  
  try {
    // Check if column exists
    final result = await DatabaseService.query(
      '''
      SELECT COUNT(*) as count
      FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'tickets'
      AND COLUMN_NAME = 'printing_notes'
      ''',
      userId: 1, // System user for migrations
    );
    
    final count = result.first['count'] as int;
    
    if (count == 0) {
      print('Adding printing_notes column to tickets table...');
      await DatabaseService.query(
        '''
        ALTER TABLE tickets
        ADD COLUMN printing_notes TEXT AFTER closed_by
        ''',
        userId: 1, // System user for migrations
      );
      print('✓ printing_notes column added successfully');
    } else {
      print('✓ printing_notes column already exists');
    }
  } catch (e) {
    print('Error adding printing_notes column: $e');
    rethrow;
  }
}

/// Analyze and optimize existing indexes
Future<void> analyzeTicketsIndexUsage(MySqlConnection conn) async {
  print('Analyzing tickets indexes usage...');
  
  try {
    // تحقق من استخدام الفهارس
    final indexUsage = await DatabaseService.query(
      '''
      SHOW INDEX FROM tickets 
      WHERE Key_name != 'PRIMARY'
    ''',
      userId: 1, // System user for utilities
    );
    
    print('Current tickets indexes:');
    for (final index in indexUsage) {
      print('- ${index['Key_name']}: ${index['Column_name']}');
    }
    
    // تحقق من إحصائيات الجداول
    final tableStats = await DatabaseService.query(
      '''
      SELECT 
        TABLE_NAME,
        TABLE_ROWS,
        DATA_LENGTH,
        INDEX_LENGTH,
        (INDEX_LENGTH / DATA_LENGTH) * 100 as INDEX_RATIO
      FROM information_schema.TABLES 
      WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME IN ('tickets', 'ticket_items', 'customers', 'ticketcall')
    ''',
      userId: 1, // System user for utilities
    );
    
    print('Table statistics:');
    for (final stat in tableStats) {
      print('${stat['TABLE_NAME']}: ${stat['TABLE_ROWS']} rows, Index ratio: ${stat['INDEX_RATIO']?.toStringAsFixed(2)}%');
    }
    
  } catch (e) {
    print('Could not analyze index usage: $e');
  }
}
