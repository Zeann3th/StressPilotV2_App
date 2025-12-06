class RequestLog {
  final int? id;
  final int? runId;
  final int? endpointId;
  final int? statusCode;
  final int? responseTime;
  final String? request;
  final String? response;
  final String? createdAt;

  RequestLog({
    this.id,
    this.runId,
    this.endpointId,
    this.statusCode,
    this.responseTime,
    this.request,
    this.response,
    this.createdAt,
  });

  factory RequestLog.fromJson(Map<String, dynamic> json) {
    return RequestLog(
      id: json['id'],
      runId: json['runId'],
      endpointId: json['endpointId'],
      statusCode: json['statusCode'],
      responseTime: json['responseTime'],
      request: json['request'],
      response: json['response'],
      createdAt: json['createdAt'],
    );
  }
}
