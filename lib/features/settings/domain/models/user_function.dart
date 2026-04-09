class UserFunction {
  final int? id;
  final String name;
  final String body;
  final String? description;
  final bool? active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserFunction({
    this.id,
    required this.name,
    required this.body,
    this.description,
    this.active,
    this.createdAt,
    this.updatedAt,
  });

  factory UserFunction.fromJson(Map<String, dynamic> json) {
    return UserFunction(
      id: json['id'] as int?,
      name: json['name'] as String,
      body: json['body'] as String,
      description: json['description'] as String?,
      active: json['active'] as bool?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'body': body,
      'description': description,
      'active': active,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  UserFunction copyWith({
    int? id,
    String? name,
    String? body,
    String? description,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserFunction(
      id: id ?? this.id,
      name: name ?? this.name,
      body: body ?? this.body,
      description: description ?? this.description,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
