class City {
  final int id;
  final String name;
  final int governorateId;

  City({required this.id, required this.name, required this.governorateId});

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'] as int,
      name: json['name'] as String,
      governorateId: json['governorate_id'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'governorate_id': governorateId,
    };
  }
} 