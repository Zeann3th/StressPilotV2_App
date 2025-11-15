class CreateFlowRequest {
  final int projectId;
  final String name;
  final String? description;

  CreateFlowRequest({required this.projectId, required this.name, this.description});

  Map<String, dynamic> toJson() => {
    'projectId': projectId,
    'name': name,
    if (description != null) 'description': description,
  };
}

class RunFlowRequest {
  final int threads;
  final int totalDuration;
  final int rampUpDuration;
  final Map<String, dynamic> variables;

  RunFlowRequest({
    required this.threads,
    required this.totalDuration,
    required this.rampUpDuration,
    Map<String, dynamic>? variables,
  }) : variables = variables ?? {};

  Map<String, dynamic> toJson() => {
    'threads': threads,
    'totalDuration': totalDuration,
    'rampUpDuration': rampUpDuration,
    'variables': variables,
  };
}

class Flow {
  final int id;
  final int projectId;
  final String name;
  final String? description;
  final List<FlowStep> steps;

  Flow({
    required this.id,
    required this.projectId,
    required this.name,
    this.description,
    required this.steps,
  });

  factory Flow.fromJson(Map<String, dynamic> json) => Flow(
    id: json['id'],
    projectId: json['projectId'],
    name: json['name'],
    description: json['description'],
    steps: (json['steps'] as List<dynamic>?)
        ?.map((e) => FlowStep.fromJson(e as Map<String, dynamic>))
        .toList() ??
        [],
  );
}

class FlowStep {
  final String id;
  final String type;
  final int? endpointId;
  final Map<String, dynamic>? preProcessor;
  final Map<String, dynamic>? postProcessor;
  final String? nextIfTrue;
  final String? nextIfFalse;
  final String? condition;

  FlowStep({
    required this.id,
    required this.type,
    this.endpointId,
    this.preProcessor,
    this.postProcessor,
    this.nextIfTrue,
    this.nextIfFalse,
    this.condition,
  });

  factory FlowStep.fromJson(Map<String, dynamic> json) => FlowStep(
    id: json['id'],
    type: json['type'],
    endpointId: json['endpointId'],
    preProcessor: json['preProcessor'],
    postProcessor: json['postProcessor'],
    nextIfTrue: json['nextIfTrue'],
    nextIfFalse: json['nextIfFalse'],
    condition: json['condition'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'endpointId': endpointId,
    'preProcessor': preProcessor,
    'postProcessor': postProcessor,
    'nextIfTrue': nextIfTrue,
    'nextIfFalse': nextIfFalse,
    'condition': condition,
  };
}
