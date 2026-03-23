class PluginDependency {
  final String pluginId;
  final String? version;
  final bool optional;

  PluginDependency({
    required this.pluginId,
    this.version,
    this.optional = false,
  });

  factory PluginDependency.fromJson(Map<String, dynamic> json) {
    return PluginDependency(
      pluginId: json['pluginId'] as String,
      version: json['version'] as String?,
      optional: json['optional'] as bool? ?? false,
    );
  }
}

class PluginDescriptor {
  final String pluginId;
  final String? pluginDescription;
  final String? pluginClass;
  final String version;
  final String? requires;
  final String? provider;
  final String? license;
  final List<PluginDependency> dependencies;

  PluginDescriptor({
    required this.pluginId,
    this.pluginDescription,
    this.pluginClass,
    required this.version,
    this.requires,
    this.provider,
    this.license,
    required this.dependencies,
  });

  factory PluginDescriptor.fromJson(Map<String, dynamic> json) {
    return PluginDescriptor(
      pluginId: json['pluginId'] as String,
      pluginDescription: json['pluginDescription'] as String?,
      pluginClass: json['pluginClass'] as String?,
      version: json['version'] as String? ?? '0.0.0',
      requires: json['requires'] as String?,
      provider: json['provider'] as String?,
      license: json['license'] as String?,
      dependencies: (json['dependencies'] as List? ?? [])
          .map((e) => PluginDependency.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
