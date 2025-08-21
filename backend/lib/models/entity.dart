class Entity {
  final int? id;
  final String name;

  Entity({
    this.id,
    required this.name,
  });

  factory Entity.fromMap(Map<String, dynamic> map) {
    return Entity(
      id: map['id'] as int?,
      name: map['name'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  @override
  String toString() {
    return 'Entity{id: $id, name: $name}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Entity && other.id == id && other.name == name;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}