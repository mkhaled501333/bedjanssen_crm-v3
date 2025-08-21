class CustomerPhone {
  final int id;
  final int companyId;
  final int customerId;
  final String? phone;
  final int? phoneType;
  final int? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CustomerPhone({
    required this.id,
    required this.companyId,
    required this.customerId,
    this.phone,
    this.phoneType,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory CustomerPhone.fromJson(Map<String, dynamic> json) {
    return CustomerPhone(
      id: json['id'] as int,
      companyId: json['company_id'] as int,
      customerId: json['customer_id'] as int,
      phone: json['phone'] as String?,
      phoneType: json['phone_type'] as int?,
      createdBy: json['created_by'] as int?,
      createdAt: json['created_at'] == null
          ? null
          : json['created_at'] is DateTime 
              ? json['created_at'] as DateTime
              : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : json['updated_at'] is DateTime 
              ? json['updated_at'] as DateTime
              : DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'customer_id': customerId,
      'phone': phone,
      'phone_type': phoneType,
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}