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

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  factory RequestLog.fromJson(Map<String, dynamic> json) {
    return RequestLog(
      id: _parseInt(json['id']),
      runId: _parseInt(json['runId']),
      endpointId: _parseInt(json['endpointId']),
      statusCode: _parseInt(json['statusCode']),
      responseTime: _parseInt(json['responseTime']),
      request: json['request'],
      response: json['response'],
      createdAt: json['createdAt'],
    );
  }
}
