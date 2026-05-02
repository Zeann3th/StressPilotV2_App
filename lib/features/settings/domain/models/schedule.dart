class Schedule {
  final int id;
  final int flowId;
  final String quartzExpr;
  final bool enabled;
  final int threads;
  final int duration;
  final int rampUp;
  final DateTime createdAt;
  final DateTime updatedAt;

  Schedule({
    required this.id,
    required this.flowId,
    required this.quartzExpr,
    required this.enabled,
    required this.threads,
    required this.duration,
    required this.rampUp,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'] as int,
      flowId: json['flowId'] as int,
      quartzExpr: json['quartzExpr'] as String,
      enabled: json['enabled'] as bool,
      threads: json['threads'] as int,
      duration: json['duration'] as int,
      rampUp: json['rampUp'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'flowId': flowId,
        'quartzExpr': quartzExpr,
        'enabled': enabled,
        'threads': threads,
        'duration': duration,
        'rampUp': rampUp,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  Schedule copyWith({
    int? flowId,
    String? quartzExpr,
    bool? enabled,
    int? threads,
    int? duration,
    int? rampUp,
  }) {
    return Schedule(
      id: id,
      flowId: flowId ?? this.flowId,
      quartzExpr: quartzExpr ?? this.quartzExpr,
      enabled: enabled ?? this.enabled,
      threads: threads ?? this.threads,
      duration: duration ?? this.duration,
      rampUp: rampUp ?? this.rampUp,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class CreateScheduleRequest {
  final int flowId;
  final String quartzExpr;
  final int threads;
  final int duration;
  final int rampUp;
  final bool enabled;

  CreateScheduleRequest({
    required this.flowId,
    required this.quartzExpr,
    this.threads = 1,
    this.duration = 60,
    this.rampUp = 0,
    this.enabled = true,
  });

  Map<String, dynamic> toJson() => {
        'flowId': flowId,
        'quartzExpr': quartzExpr,
        'threads': threads,
        'duration': duration,
        'rampUp': rampUp,
        'enabled': enabled,
      };
}
