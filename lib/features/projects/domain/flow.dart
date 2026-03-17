import 'dart:convert';

class Flow {
  final int id;
  final String name;
  final String? description;
  final String type;
  final int projectId;
  final List<FlowStep> steps;

  static Map<String, dynamic>? _parseProcessor(dynamic value) {
    if (value == null) return null;
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String) {
      if (value.isEmpty) return null;
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Flow({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    required this.projectId,
    this.steps = const [],
  });

  static int _toInt(dynamic value, [int defaultValue = 0]) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  factory Flow.fromJson(Map<String, dynamic> json) {
    return Flow(
      id: _toInt(json['id']),
      name: json['name'] ?? '',
      description: json['description'],
      type: json['type'] ?? 'DEFAULT',
      projectId: _toInt(json['projectId'] ?? json['project_id']),
      steps:
          (json['steps'] as List?)?.map((e) => FlowStep.fromJson(e)).toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'type': type,
    'projectId': projectId,
    'steps': steps.map((e) => e.toJson()).toList(),
  };

  Flow copyWith({List<FlowStep>? steps}) {
    return Flow(
      id: id,
      name: name,
      description: description,
      type: type,
      projectId: projectId,
      steps: steps ?? this.steps,
    );
  }
}

class FlowStep {
  final String id;
  final String type;
  final int? endpointId;
  final String? nextIfTrue;
  final String? nextIfFalse;
  final String? condition;
  final Map<String, dynamic>? preProcessor;
  final Map<String, dynamic>? postProcessor;

  FlowStep({
    required this.id,
    required this.type,
    this.endpointId,
    this.nextIfTrue,
    this.nextIfFalse,
    this.condition,
    this.preProcessor,
    this.postProcessor,
  });

  factory FlowStep.fromJson(Map<String, dynamic> json) {
    return FlowStep(
      id: json['id'] ?? '',
      type: json['type'] ?? 'ENDPOINT',
      endpointId: json['endpointId'] ?? json['endpoint_id'],
      nextIfTrue: json['nextIfTrue'] ?? json['next_if_true'],
      nextIfFalse: json['nextIfFalse'] ?? json['next_if_false'],
      condition: json['condition'],
      preProcessor: Flow._parseProcessor(json['preProcessor'] ?? json['pre_processor']),
      postProcessor: Flow._parseProcessor(json['postProcessor'] ?? json['post_processor']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'endpointId': endpointId,
      'nextIfTrue': nextIfTrue,
      'nextIfFalse': nextIfFalse,
      'condition': condition,
      'preProcessor': preProcessor,
      'postProcessor': postProcessor,
    };
  }
}

class CreateFlowRequest {
  final int projectId;
  final String name;
  final String? description;
  final String type;

  CreateFlowRequest({
    required this.projectId,
    required this.name,
    this.description,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
    'projectId': projectId,
    'name': name,
    'description': description,
    'type': type,
  };
}

class RunFlowRequest {
  final int threads;
  final int totalDuration;
  final int rampUpDuration;
  final Map<String, dynamic>? variables;

  RunFlowRequest({
    this.threads = 1,
    this.totalDuration = 60,
    this.rampUpDuration = 0,
    this.variables,
  });

  Map<String, dynamic> toJson() => {
    'threads': threads,
    'totalDuration': totalDuration,
    'rampUpDuration': rampUpDuration,
    'variables': variables,
  };
}
