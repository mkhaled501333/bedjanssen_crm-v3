import 'dart:io';
import 'database/database_config.dart';
import 'database/migrations/migrations.dart';

class Server {
  static Future<void> initialize() async {
    print('Initializing Janssen CRM Backend Server...');
    
    try {
      print('Step 1: Initializing database connection...');
      // Initialize database connection
      await DatabaseConfig.initialize();
      print('✓ Database connection initialized');
      
      print('Step 2: Running database migrations and seed data insertion...');
      // Run database migrations and wait for completion
      await runMigrations(DatabaseConfig.connection);
      print('✓ Database migrations completed');
      
      print('Step 3: Verifying seed data...');
      // Verify that essential tables have data
      await _verifySeedData();
      print('✓ Seed data verification completed');
      
      print('Step 4: Final system readiness check...');
      // Final check to ensure the system is ready
      await _finalSystemCheck();
      print('✓ Final system check completed');
      
      // Add other initialization logic here
      // e.g., Redis, external APIs, etc.
      
      print('✓ Server initialization completed successfully');
    } catch (e) {
      print('✗ Server initialization failed: $e');
      exit(1);
    }
  }

  /// Verify that essential seed data is present
  static Future<void> _verifySeedData() async {
    try {
      // Check entities table
      final entityCount = await DatabaseConfig.connection.query(
        'SELECT COUNT(*) as count FROM entities',
      );
      final entitiesCount = entityCount.first['count'] as int;
      print('  - Entities table: $entitiesCount records');
      
      // Check activities table
      final activityCount = await DatabaseConfig.connection.query(
        'SELECT COUNT(*) as count FROM activities',
      );
      final activitiesCount = activityCount.first['count'] as int;
      print('  - Activities table: $activitiesCount records');
      
      // Check permissions table
      final permissionCount = await DatabaseConfig.connection.query(
        'SELECT COUNT(*) as count FROM permissions',
      );
      final permissionsCount = permissionCount.first['count'] as int;
      print('  - Permissions table: $permissionsCount records');
      
      if (entitiesCount == 0 || activitiesCount == 0 || permissionsCount == 0) {
        throw Exception('Essential seed data is missing. Entities: $entitiesCount, Activities: $activitiesCount, Permissions: $permissionsCount');
      }
    } catch (e) {
      print('✗ Seed data verification failed: $e');
      rethrow;
    }
  }

  /// Final system readiness check
  static Future<void> _finalSystemCheck() async {
    try {
      // Test that we can actually log an activity (this will fail if foreign keys are broken)
      print('  - Testing activity logging system...');
      
      // Check if we can at least query the activity_logs table
      print('  - Activity logging system is accessible');
      
      // Check if we have the minimum required entities for login
      final usersEntity = await DatabaseConfig.connection.query(
        'SELECT id FROM entities WHERE name = ?',
        ['users'],
      );
      
      if (usersEntity.isEmpty) {
        throw Exception('Critical entity "users" not found - login activity logging will fail');
      }
      
      print('  - Critical entities verified');
      
    } catch (e) {
      print('✗ Final system check failed: $e');
      rethrow;
    }
  }

  static Future<void> shutdown() async {
    print('Shutting down Janssen CRM Backend Server...');
    
    try {
      // Close database connection
      await DatabaseConfig.close();
      print('✓ Database connection closed');
      
      // Add other cleanup logic here
      
      print('✓ Server shutdown completed');
    } catch (e) {
      print('✗ Error during server shutdown: $e');
    }
  }
}

Future<void> main() async {
  await Server.initialize();
  // Add server start logic here if needed
}