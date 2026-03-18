import 'dart:convert';

class Flow {
  final int id;
  final String name;
  final String? description;
  final String type;
  final int projectId;
  final List<FlowStep> steps;

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

  static Map<String, dynamic>? _parseProcessor(dynamic value) {
    if (value == null) return null;
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String) {
      if (value.isEmpty) return null;
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  factory Flow.fromJson(Map<String, dynamic> json) {
    return Flow(
      id: _toInt(json['id']),
      name: json['name'] ?? '',
      description: json['description'],
      type: json['type'] ?? 'DEFAULT',
      projectId: _toInt(json['projectId']),
      steps:
      (json['steps'] as List?)
          ?.map((e) => FlowStep.fromJson(e as Map<String, dynamic>))
          .toList() ??
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

  final String? endpointName;
  final String? endpointUrl;
  final String? endpointType;
  final String? endpointMethod;

  final String? nextIfTrue;
  final String? nextIfFalse;
  final String? condition;
  final Map<String, dynamic>? preProcessor;
  final Map<String, dynamic>? postProcessor;

  FlowStep({
    required this.id,
    required this.type,
    this.endpointId,
    this.endpointName,
    this.endpointUrl,
    this.endpointType,
    this.endpointMethod,
    this.nextIfTrue,
    this.nextIfFalse,
    this.condition,
    this.preProcessor,
    this.postProcessor,
  });

  factory FlowStep.fromJson(Map<String, dynamic> json) {

    final endpointObj = json['endpoint'];
    int? endpointId;
    String? endpointName;
    String? endpointUrl;
    String? endpointType;
    String? endpointMethod;

    if (endpointObj is Map<String, dynamic>) {

      endpointId    = Flow._toInt(endpointObj['id']);
      endpointName  = endpointObj['name']?.toString();
      endpointUrl   = endpointObj['url']?.toString();
      endpointType  = endpointObj['type']?.toString();
      endpointMethod = endpointObj['httpMethod']?.toString()
          ?? endpointObj['method']?.toString();
    } else {

      final raw = json['endpointId'];
      endpointId = raw == null ? null : Flow._toInt(raw);
    }

    return FlowStep(
      id:             json['id']?.toString() ?? '',
      type:           json['type']?.toString() ?? 'ENDPOINT',
      endpointId:     endpointId,
      endpointName:   endpointName,
      endpointUrl:    endpointUrl,
      endpointType:   endpointType,
      endpointMethod: endpointMethod,
      nextIfTrue:     json['nextIfTrue']?.toString(),
      nextIfFalse:    json['nextIfFalse']?.toString(),
      condition:      json['condition']?.toString(),
      preProcessor:   Flow._parseProcessor(json['preProcessor']),
      postProcessor:  Flow._parseProcessor(json['postProcessor']),
    );
  }

  Map<String, dynamic> toJson({bool includeMetadata = true}) {
    Map<String, dynamic> pre;
    if (preProcessor == null) {
      pre = {};
    } else {
      pre = Map<String, dynamic>.from(preProcessor!);
      if (!includeMetadata) {
        pre.remove('location');
        pre.remove('_canvas_x');
        pre.remove('_canvas_y');
      }
    }

    final Map<String, dynamic> json = {
      'id':           id,
      'type':         type,
      'endpointId':   endpointId,
      'nextIfTrue':   nextIfTrue,
      'nextIfFalse':  nextIfFalse,
      'condition':    condition,
      'postProcessor':postProcessor,
    };

    if (pre.isNotEmpty) {
      json['preProcessor'] = pre;
    }

    return json;
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
    'projectId':   projectId,
    'name':        name,
    'description': description,
    'type':        type,
  };
}

class RunFlowRequest {
  final int threads;
  final int totalDuration;
  final int rampUpDuration;
  final Map<String, dynamic>? variables;

  RunFlowRequest({
    this.threads        = 1,
    this.totalDuration  = 60,
    this.rampUpDuration = 0,
    this.variables,
  });

  Map<String, dynamic> toJson() => {
    'threads':        threads,
    'totalDuration':  totalDuration,
    'rampUpDuration': rampUpDuration,
    'variables':      variables,
  };
}
