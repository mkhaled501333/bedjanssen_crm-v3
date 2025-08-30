import 'dart:convert';
import '../database/database_service.dart';

class User {
  final int? id;
  final int companyId;
  final String name;
  final String username;
  final String password;
  final int? createdBy;
  final bool isActive;
  final List<int> permissions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    this.id,
    required this.companyId,
    required this.name,
    required this.username,
    required this.password,
    this.createdBy,
    this.isActive = true,
    this.permissions = const [],
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'company_id': companyId,
      'name': name,
      'username': username,
      'password': password,
      'created_by': createdBy,
      'is_active': isActive ? 1 : 0,
      'permissions': jsonEncode(permissions),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      companyId: map['company_id'] as int,
      name: map['name'] as String,
      username: map['username'] as String,
      password: map['password'] as String,
      createdBy: map['created_by'] as int?,
      isActive: (map['is_active'] is int ? map['is_active'] == 1 : map['is_active'] == true),
      permissions: map['permissions'] != null 
          ? List<int>.from(jsonDecode(map['permissions'] as String) as List)
          : [],
      createdAt: map['created_at'] != null 
          ? (map['created_at'] is DateTime 
              ? map['created_at'] as DateTime
              : DateTime.parse(map['created_at'].toString())) 
          : null,
      updatedAt: map['updated_at'] != null 
          ? (map['updated_at'] is DateTime 
              ? map['updated_at'] as DateTime
              : DateTime.parse(map['updated_at'].toString())) 
          : null,
    );
  }

  /// Create the users table
  static Future<void> createTable() async {
    const sql = '''
      CREATE TABLE IF NOT EXISTS users (
        id INT AUTO_INCREMENT PRIMARY KEY,
        company_id INT NOT NULL,
        name VARCHAR(255) NOT NULL,
        username VARCHAR(255) UNIQUE NOT NULL,
        password VARCHAR(255) NOT NULL,
        created_by INT,
        is_active BOOLEAN DEFAULT TRUE,
        permissions JSON DEFAULT '[]',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )
    ''';
    
    await DatabaseService.query(sql);
  }

  /// Save user to database
  Future<User> save() async {
    if (id == null) {
      // Insert new user
      
      final insertId = await DatabaseService.insert(
        'users',
        {
          'company_id': companyId,
          'name': name,
          'username': username,
          'password': password,
          'created_by': createdBy,
          'is_active': isActive ? 1 : 0,
          'permissions': jsonEncode(permissions),
        },
        userId: createdBy,
      );
      
      if (insertId > 0) {
        // Fetch the created user to get timestamps
        final createdUser = await findById(insertId);
        if (createdUser != null) {
          return createdUser;
        }
      }
      throw Exception('Failed to create user');
    } else {
      // Update existing user
      
      final affectedRows = await DatabaseService.update(
        'users',
        {
          'company_id': companyId,
          'name': name,
          'username': username,
          'password': password,
          'created_by': createdBy,
          'is_active': isActive ? 1 : 0,
          'permissions': jsonEncode(permissions),
        },
        'id = ?',
        whereParameters: [id],
        userId: createdBy,
      );
      
      if (affectedRows > 0) {
        // Fetch the updated user to get new timestamp
        final updatedUser = await findById(id!);
        if (updatedUser != null) {
          return updatedUser;
        }
      }
      throw Exception('Failed to update user');
    }
  }

  /// Find user by ID
  static Future<User?> findById(int id) async {
    const sql = 'SELECT * FROM users WHERE id = ?';
    final result = await DatabaseService.queryOne(
      sql,
      parameters: [id],
      userId: 1, // System user for read operations
    );
    
    return result != null ? User.fromMap(result.fields) : null;
  }

  /// Find user by username
  static Future<User?> findByUsername(String username) async {
    const sql = 'SELECT * FROM users WHERE username = ?';
    final result = await DatabaseService.queryOne(
      sql,
      parameters: [username],
      userId: 1, // System user for read operations
    );
    
    return result != null ? User.fromMap(result.fields) : null;
  }

  /// Get all users
  static Future<List<User>> findAll() async {
    const sql = 'SELECT * FROM users ORDER BY created_at DESC';
    final results = await DatabaseService.queryMany(
      sql,
      userId: 1, // System user for read operations
    );
    
    return results.map((row) => User.fromMap(row.fields)).toList();
  }

  /// Find users with pagination
  static Future<List<User>> findWithPagination({
    int limit = 10,
    int offset = 0,
  }) async {
    const sql = '''
      SELECT * FROM users 
      ORDER BY created_at DESC 
      LIMIT ? OFFSET ?
    ''';
    final results = await DatabaseService.queryMany(
      sql,
      parameters: [limit, offset],
      userId: 1, // System user for read operations
    );
    
    return results.map((row) => User.fromMap(row.fields)).toList();
  }

  /// Count total users
  static Future<int> count() async {
    const sql = 'SELECT COUNT(*) as total FROM users';
    final result = await DatabaseService.queryOne(
      sql,
      userId: 1, // System user for read operations
    );
    return result?['total'] as int? ?? 0;
  }

  /// Search users by name or email
  static Future<List<User>> search(String query) async {
    const sql = '''
      SELECT * FROM users 
      WHERE name LIKE ? 
         OR username LIKE ? 
      ORDER BY created_at DESC
    ''';
    final searchTerm = '%$query%';
    final results = await DatabaseService.queryMany(
      sql,
      parameters: [searchTerm, searchTerm],
      userId: 1, // System user for read operations
    );
    
    return results.map((row) => User.fromMap(row.fields)).toList();
  }

  /// Delete user
  Future<bool> delete() async {
    if (id == null) return false;
    
    final affectedRows = await DatabaseService.delete(
      'users',
      'id = ?',
      parameters: [id],
      userId: createdBy,
    );
    
    return affectedRows > 0;
  }

  /// Check if username exists (for validation)
  static Future<bool> usernameExists(String username, {int? excludeId}) async {
    String sql = 'SELECT COUNT(*) as count FROM users WHERE username = ?';
    List<Object?> parameters = [username];
    
    if (excludeId != null) {
      sql += ' AND id != ?';
      parameters.add(excludeId);
    }
    
    final result = await DatabaseService.queryOne(
      sql, 
      parameters: parameters,
      userId: 1, // System user for read operations
    );
    final count = result?['count'] as int? ?? 0;
    return count > 0;
  }

  @override
  String toString() {
    return 'User{id: $id, username: $username, name: $name, companyId: $companyId, permissions: $permissions}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id && other.username == username;
  }

  @override
  int get hashCode => id.hashCode ^ username.hashCode;
}