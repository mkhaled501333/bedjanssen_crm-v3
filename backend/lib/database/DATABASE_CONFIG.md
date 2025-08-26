# Database Configuration

This document explains how to configure the database connection for the Janssen CRM backend.

## Configuration Options

### Option 1: Local Development (Recommended for development)

When running the backend locally (outside Docker), edit `lib/database/config.dart`:

```dart
class Config {
  // Database Configuration for local development
  static const String dbHost = 'localhost';
  static const int dbPort = 3306;  // Local MySQL port
  static const String dbName = 'janssencrm';
  static const String dbUser = 'root';
  static const String dbPassword = 'Admin@1234';
  static const bool dbUseSSL = false;
}
```

### Option 2: Docker Environment

When running the backend inside Docker, edit `lib/database/config.dart`:

```dart
class Config {
  // Database Configuration for Docker environment
  static const String dbHost = 'mysql';  // Docker service name
  static const int dbPort = 3306;        // Internal Docker port
  static const String dbName = 'janssencrm';
  static const String dbUser = 'root';
  static const String dbPassword = 'Admin@1234';
  static const bool dbUseSSL = false;
}
```

## Port Mapping

**Local Development**:
- MySQL runs directly on your machine at `localhost:3306`
- No port mapping needed

**Docker Environment**:
- The `docker-compose.yml` maps MySQL port 3306 (internal) to 3307 (external)
- Inside Docker containers: Use port 3306
- Outside Docker (if accessing from host): Use port 3307

## Quick Switch

To quickly switch between local and Docker development:

1. **For local development**: Use the current configuration (localhost:3306)
2. **For Docker**: Comment out the local config and uncomment the Docker config in `config.dart`

## Troubleshooting

### Connection Refused
- Ensure MySQL is running on your local machine
- Check if port 3306 is available and not blocked by firewall
- Verify the database credentials
- Make sure the `janssencrm` database exists

### Host Not Found
- When running locally, make sure you're using `localhost` not `mysql`
- When running in Docker, make sure you're using `mysql` not `localhost`

### Port Already in Use
- If port 3306 is already in use, you can:
  - Stop other MySQL instances
  - Change the port in your local MySQL configuration
  - Use a different port and update `config.dart` accordingly
