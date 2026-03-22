class PluginCapability {
  final String id;
  final String name;
  final String category;
  final List<String> requiredFields;

  PluginCapability({
    required this.id,
    required this.name,
    required this.category,
    this.requiredFields = const []
  });

  factory PluginCapability.fromJson(Map<String, dynamic> json) {
    return PluginCapability(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      requiredFields: List<String>.from(json['requiredFields'] ?? []),
    );
  }
}
