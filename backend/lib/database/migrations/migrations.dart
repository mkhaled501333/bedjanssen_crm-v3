import 'package:mysql1/mysql1.dart';
import 'index.dart';

/// Main migration orchestrator
Future<void> runMigrations(MySqlConnection conn) async {
  try {
    print('Starting database migrations...');

    // Create basic tables
    await createBasicTables(conn);

    // Create optimized indexes for tickets report service
    await createOptimizedTicketsReportIndexes(conn);

    // Create additional indexes for ticket items report view optimization
    await createTicketItemsReportIndexes(conn);

    // Create ticket items report view
    await createTicketItemsReportView(conn);

    // Insert activities data
    await insertActivitiesData(conn);

    print('✓ All migrations completed: database schema and indexes ensured.');
  } catch (e) {
    print('✗ Migration failed: $e');
    rethrow;
  }
}
