class Activity {
  final int? id;
  final String name;
  final String? description;
  final DateTime createdAt;

  Activity({
    this.id,
    required this.name,
    this.description,
    required this.createdAt,
  });

  factory Activity.fromMap(Map<String, dynamic> map) {
    return Activity(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      createdAt: map['created_at'] is DateTime 
          ? map['created_at'] as DateTime
          : DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Activity{id: $id, name: $name, description: $description, createdAt: $createdAt}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Activity &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        description.hashCode ^
        createdAt.hashCode;
  }
}