// ignore_for_file: inference_failure_on_instance_creation, public_member_api_docs

import 'package:mysql1/mysql1.dart';

class DatabaseConfig {
  static late MySqlConnection _connection;
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    // Load environment variables
    const host = 'localhost';
    const port = 3306;
    const database = 'janssencrm';
    const username = 'root';
    const password = 'Admin@1234';
    const useSSL = false;

    int retries = 0;
    const maxRetries = 10;
    const retryDelay = Duration(seconds: 3);
    while (retries < maxRetries) {
      try {
        final settings = ConnectionSettings(
          host: host,
          port: port,
          user: username,
          password: password,
          db: database,
          useSSL: useSSL,
        );

        _connection = await MySqlConnection.connect(settings);
        _isInitialized = true;
        print('MySQL database connection established successfully');
        return;
      } catch (e) {
        retries++;
        print('Failed to connect to MySQL database (attempt $retries/$maxRetries): $e');
        if (retries >= maxRetries) {
          print('Giving up after $maxRetries attempts.');
          rethrow;
        }
        await Future.delayed(retryDelay);
      }
    }
  }

  static MySqlConnection get connection {
    if (!_isInitialized) {
      throw StateError('Database not initialized. Call DatabaseConfig.initialize() first.');
    }
    return _connection;
  }

  static Future<void> close() async {
    if (_isInitialized) {
      await _connection.close();
      _isInitialized = false;
      print('MySQL database connection closed');
    }
  }

  static Future<void> reconnect() async {
    try {
      if (_isInitialized) {
        await _connection.close();
      }
      _isInitialized = false;
      await initialize();
      print('Database reconnection successful');
    } catch (e) {
      print('Database reconnection failed: $e');
      rethrow;
    }
  }

  static bool get isInitialized => _isInitialized;
}