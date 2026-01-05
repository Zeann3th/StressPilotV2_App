class Endpoint {
  final int id;
  final String name;
  final String? description;
  final String type;
  final String url;
  final String? httpMethod;
  final Map<String, dynamic>? httpHeaders;
  final dynamic body;
  final Map<String, dynamic>? httpParameters;
  final String? grpcServiceName;
  final String? grpcMethodName;
  final String? grpcStubPath;
  final String? graphqlOperationType;
  final Map<String, dynamic>? graphqlVariables;
  final String? successCondition;
  final int projectId;

  Endpoint({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    required this.url,
    this.httpMethod,
    this.httpHeaders,
    this.body,
    this.httpParameters,
    this.grpcServiceName,
    this.grpcMethodName,
    this.grpcStubPath,
    this.graphqlOperationType,
    this.graphqlVariables,
    this.successCondition,
    required this.projectId,
  });

  factory Endpoint.fromJson(Map<String, dynamic> json) => Endpoint(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    type: json['type'],
    url: json['url'],
    httpMethod: json['httpMethod'],
    httpHeaders: json['httpHeaders'] as Map<String, dynamic>?,
    body: json['body'],
    httpParameters: json['httpParameters'] as Map<String, dynamic>?,
    grpcServiceName: json['grpcServiceName'],
    grpcMethodName: json['grpcMethodName'],
    grpcStubPath: json['grpcStubPath'],
    graphqlOperationType: json['graphqlOperationType'],
    graphqlVariables: json['graphqlVariables'] as Map<String, dynamic>?,
    successCondition: json['successCondition'],
    projectId: json['projectId'],
  );
}
