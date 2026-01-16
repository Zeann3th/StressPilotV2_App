class RequestEntry {
  final String id;
  final String url;
  final String method;
  final int? statusCode;
  final String? statusText;
  final Map<String, String> requestHeaders;
  final Map<String, String> responseHeaders;
  final dynamic requestBody;
  final dynamic responseBody;
  final DateTime timestamp;
  final int durationMs;
  final String? resourceType;

  RequestEntry({
    required this.id,
    required this.url,
    required this.method,
    this.statusCode,
    this.statusText,
    this.requestHeaders = const {},
    this.responseHeaders = const {},
    this.requestBody,
    this.responseBody,
    required this.timestamp,
    this.durationMs = 0,
    this.resourceType,
  });

  RequestEntry copyWith({
    String? id,
    String? url,
    String? method,
    int? statusCode,
    String? statusText,
    Map<String, String>? requestHeaders,
    Map<String, String>? responseHeaders,
    dynamic requestBody,
    dynamic responseBody,
    DateTime? timestamp,
    int? durationMs,
    String? resourceType,
  }) {
    return RequestEntry(
      id: id ?? this.id,
      url: url ?? this.url,
      method: method ?? this.method,
      statusCode: statusCode ?? this.statusCode,
      statusText: statusText ?? this.statusText,
      requestHeaders: requestHeaders ?? this.requestHeaders,
      responseHeaders: responseHeaders ?? this.responseHeaders,
      requestBody: requestBody ?? this.requestBody,
      responseBody: responseBody ?? this.responseBody,
      timestamp: timestamp ?? this.timestamp,
      durationMs: durationMs ?? this.durationMs,
      resourceType: resourceType ?? this.resourceType,
    );
  }
}
