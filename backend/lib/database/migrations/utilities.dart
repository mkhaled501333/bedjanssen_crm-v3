import 'package:mysql1/mysql1.dart';
import '../database_service.dart';

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
