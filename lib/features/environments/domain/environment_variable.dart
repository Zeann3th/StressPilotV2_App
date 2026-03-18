class EnvironmentVariable {
  final int id;
  final int environmentId;
  final String key;
  final String value;
  final bool isActive;

  EnvironmentVariable({
    required this.id,
    required this.environmentId,
    required this.key,
    required this.value,
    required this.isActive,
  });

  static int _toInt(dynamic value, [int defaultValue = 0]) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  factory EnvironmentVariable.fromJson(Map<String, dynamic> json) {
    return EnvironmentVariable(
      id: _toInt(json['id']),
      environmentId: _toInt(json['environmentId']),
      key: json['key'] ?? '',
      value: json['value'] ?? '',
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'environmentId': environmentId,
    'key': key,
    'value': value,
    'isActive': isActive,
  };

  EnvironmentVariable copyWith({
    int? id,
    int? environmentId,
    String? key,
    String? value,
    bool? isActive,
  }) {
    return EnvironmentVariable(
      id: id ?? this.id,
      environmentId: environmentId ?? this.environmentId,
      key: key ?? this.key,
      value: value ?? this.value,
      isActive: isActive ?? this.isActive,
    );
  }
}
