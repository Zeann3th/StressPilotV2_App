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
      projectId: _toInt(json['projectId'] ?? json['project_id']),
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

  /// The endpoint id — extracted from either:
  ///   • a flat  `"endpointId": 5`  field  (sent by the client to the backend)
  ///   • a nested `"endpoint": { "id": 5, ... }` object  (returned by the backend)
  final int? endpointId;

  /// Endpoint metadata fields populated when the backend returns a nested
  /// endpoint object.  These are only used for display enrichment inside
  /// rebuildFromSteps and are never serialised back to the backend.
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
    // The backend stores the endpoint as a nested object on the step entity.
    // Extract the id and display fields from it so the canvas can render
    // nodes correctly without needing a separate endpoint list lookup.
    final endpointObj = json['endpoint'];
    int? endpointId;
    String? endpointName;
    String? endpointUrl;
    String? endpointType;
    String? endpointMethod;

    if (endpointObj is Map<String, dynamic>) {
      // Nested object form — returned by the backend after save/load.
      endpointId    = Flow._toInt(endpointObj['id']);
      endpointName  = endpointObj['name']?.toString();
      endpointUrl   = endpointObj['url']?.toString();
      endpointType  = endpointObj['type']?.toString();
      endpointMethod = endpointObj['httpMethod']?.toString()
          ?? endpointObj['http_method']?.toString()
          ?? endpointObj['method']?.toString();
    } else {
      // Flat form — used when the client sends steps back for persistence.
      final raw = json['endpointId'] ?? json['endpoint_id'];
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
      nextIfTrue:     json['nextIfTrue']?.toString()  ?? json['next_if_true']?.toString(),
      nextIfFalse:    json['nextIfFalse']?.toString() ?? json['next_if_false']?.toString(),
      condition:      json['condition']?.toString(),
      preProcessor:   Flow._parseProcessor(json['preProcessor']  ?? json['pre_processor']),
      postProcessor:  Flow._parseProcessor(json['postProcessor'] ?? json['post_processor']),
    );
  }

  /// Serialises for sending TO the backend (configure / save).
  /// Only includes endpointId — never the nested endpoint object.
  Map<String, dynamic> toJson() => {
    'id':           id,
    'type':         type,
    'endpointId':   endpointId,
    'nextIfTrue':   nextIfTrue,
    'nextIfFalse':  nextIfFalse,
    'condition':    condition,
    'preProcessor': preProcessor,
    'postProcessor':postProcessor,
  };
}

// ─── Other request/response models ───────────────────────────────────────────

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