class CapabilityDto {
  final List<String> endpointExecutors;
  final List<String> flowExecutors;
  final List<ParserCapability> parsers;

  CapabilityDto({
    required this.endpointExecutors,
    required this.flowExecutors,
    required this.parsers,
  });

  factory CapabilityDto.fromJson(Map<String, dynamic> json) {
    return CapabilityDto(
      endpointExecutors: List<String>.from(json['endpointExecutors'] ?? []),
      flowExecutors: List<String>.from(json['flowExecutors'] ?? []),
      parsers: (json['parsers'] as List?)
              ?.map((e) => ParserCapability.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class ParserCapability {
  final String name;
  final List<String> formats;

  ParserCapability({
    required this.name,
    required this.formats,
  });

  factory ParserCapability.fromJson(Map<String, dynamic> json) {
    return ParserCapability(
      name: json['name'] ?? '',
      formats: List<String>.from(json['formats'] ?? []),
    );
  }
}
