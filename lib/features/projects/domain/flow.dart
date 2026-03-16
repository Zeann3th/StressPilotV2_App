import 'dart:convert';

class Flow {
  final int id;
  final String name;
  final String? description;
  final int projectId;
  final List<FlowStep> steps;

  static Map<String, dynamic>? _parseProcessor(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is String) {
      if (value.isEmpty) return null;
      try {
        return jsonDecode(value) as Map<String, dynamic>;
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
    required this.projectId,
    this.steps = const [],
  });

  factory Flow.fromJson(Map<String, dynamic> json) {
    return Flow(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      projectId: json['projectId'] ?? json['project_id'] ?? 0,
      steps:
          (json['steps'] as List?)?.map((e) => FlowStep.fromJson(e)).toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'projectId': projectId,
    'steps': steps.map((e) => e.toJson()).toList(),
  };

  Flow copyWith({List<FlowStep>? steps}) {
    return Flow(
      id: id,
      name: name,
      description: description,
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

  CreateFlowRequest({
    required this.projectId,
    required this.name,
    this.description,
  });

  Map<String, dynamic> toJson() => {
    'projectId': projectId,
    'name': name,
    'description': description,
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
