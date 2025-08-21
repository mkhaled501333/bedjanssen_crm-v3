import 'dart:io';
import 'database/database_config.dart';
import 'database/migrations.dart';

class Server {
  static Future<void> initialize() async {
    print('Initializing Janssen CRM Backend Server...');
    
    try {
      // Initialize database connection
      await DatabaseConfig.initialize().then((value) {
        print('✓ Database connection initialized');
              // Run database migrations
       runMigrations(DatabaseConfig.connection);
      print('✓ Database migrations completed');
      
      });


      // Add other initialization logic here
      // e.g., Redis, external APIs, etc.
      
      print('✓ Server initialization completed successfully');
    } catch (e) {
      print('✗ Server initialization failed: $e');
      exit(1);
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