class NexusArtifact {
  final String id;
  final String groupId;
  final String artifactId;
  final String version;
  final String? downloadUrl;

  NexusArtifact({
    required this.id,
    required this.groupId,
    required this.artifactId,
    required this.version,
    this.downloadUrl,
  });

  factory NexusArtifact.fromJson(Map<String, dynamic> json) {
    String? jarUrl;

    // The component search returns a list of assets (pom, jar, xml, etc.)
    // We iterate to find the one that is the actual executable JAR.
    if (json['assets'] != null) {
      final assets = json['assets'] as List;
      for (var asset in assets) {
        final url = asset['downloadUrl'] as String?;
        // Robust check for standard jar extension
        if (url != null &&
            url.endsWith('.jar') &&
            !url.endsWith('-sources.jar') &&
            !url.endsWith('-javadoc.jar')) {
          jarUrl = url;
          break;
        }
      }
    }

    return NexusArtifact(
      id: json['id'] ?? '',
      groupId: json['group'] ?? '',
      artifactId: json['name'] ?? '',
      version: json['version'] ?? '',
      downloadUrl: jarUrl,
    );
  }
}
