class Run {
  final int id;
  final int flowId;
  final String status;
  final int threads; // CCU
  final int duration; // total duration in seconds
  final int rampUpDuration; // seconds
  final String? createdAt;

  Run({
    required this.id,
    required this.flowId,
    required this.status,
    required this.threads,
    required this.duration,
    required this.rampUpDuration,
    this.createdAt,
  });

  factory Run.fromJson(Map<String, dynamic> json) {
    return Run(
      id: json['id'],
      flowId: json['flowId'],
      status: json['status'] ?? '',
      threads: json['threads'] ?? 0,
      duration: json['duration'] ?? 0,
      rampUpDuration: json['rampUpDuration'] ?? 0,
      createdAt: json['createdAt'],
    );
  }
}

