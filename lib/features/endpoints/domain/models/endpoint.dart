import 'dart:convert';

class Endpoint {
  final int id;
  final String name;
  final String? description;
  final String type;
  final String? url;
  final String? httpMethod;
  final Map<String, dynamic>? httpHeaders;
  final dynamic body;
  final Map<String, dynamic>? httpParameters;
  final String? grpcServiceName;
  final String? grpcMethodName;
  final String? grpcStubPath;
  final String? graphqlOperationType;
  final Map<String, dynamic>? graphqlVariables;
  final Map<String, dynamic>? variables;
  final String? successCondition;
  final int projectId;

  static Map<String, dynamic>? _parseMap(dynamic value) {
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

  Endpoint({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    this.url,
    this.httpMethod,
    this.httpHeaders,
    this.body,
    this.httpParameters,
    this.grpcServiceName,
    this.grpcMethodName,
    this.grpcStubPath,
    this.graphqlOperationType,
    this.graphqlVariables,
    this.variables,
    this.successCondition,
    required this.projectId,
  });

  static int _toInt(dynamic value, [int defaultValue = 0]) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  factory Endpoint.fromJson(Map<String, dynamic> json) => Endpoint(
    id: _toInt(json['id']),
    name: json['name'] ?? '',
    description: json['description'],
    type: json['type'] ?? 'HTTP',
    url: json['url'],
    httpMethod: json['httpMethod'],
    httpHeaders: _parseMap(json['httpHeaders']),
    body: json['body'],
    httpParameters: _parseMap(json['httpParameters']),
    grpcServiceName: json['grpcServiceName'],
    grpcMethodName: json['grpcMethodName'],
    grpcStubPath: json['grpcStubPath'],
    graphqlOperationType: json['graphqlOperationType'],
    graphqlVariables: _parseMap(json['graphqlVariables']),
    variables: _parseMap(json['variables']),
    successCondition: json['successCondition'],
    projectId: _toInt(json['projectId']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'type': type,
    'url': url,
    'httpMethod': httpMethod,
    'httpHeaders': httpHeaders,
    'body': body,
    'httpParameters': httpParameters,
    'grpcServiceName': grpcServiceName,
    'grpcMethodName': grpcMethodName,
    'grpcStubPath': grpcStubPath,
    'graphqlOperationType': graphqlOperationType,
    'graphqlVariables': graphqlVariables,
    'variables': variables,
    'successCondition': successCondition,
    'projectId': projectId,
  };
}
