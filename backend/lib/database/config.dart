// Database configuration constants
class Config {
  // Database Configuration
  static const String dbHost = 'mysql';
  static const int dbPort = 3306;  // Local MySQL port
  static const String dbName = 'janssencrm';
  static const String dbUser = 'root';
  static const String dbPassword = 'Admin@1234';
  static const bool dbUseSSL = false;
  
  // For Docker environment, uncomment these lines:
  // static const String dbHost = 'mysql';
  // static const int dbPort = 3306;
}
