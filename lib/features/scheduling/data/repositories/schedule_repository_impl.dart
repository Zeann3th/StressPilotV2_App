import 'package:dio/dio.dart';
import 'package:stress_pilot/core/network/http_client.dart';
import 'package:stress_pilot/features/shared/domain/models/paged_response.dart';
import '../../domain/models/schedule.dart';
import '../../domain/repositories/schedule_repository.dart';

class ScheduleRepositoryImpl implements ScheduleRepository {
  final Dio _dio = HttpClient.getInstance();

  @override
  Future<PagedResponse<Schedule>> getSchedules({
    int page = 0,
    int size = 20,
  }) async {
    final response = await _dio.get(
      '/api/v1/schedules',
      queryParameters: {
        'page': page,
        'size': size,
      },
    );

    return PagedResponse.fromJson(
        response.data['data'], (json) => Schedule.fromJson(json));
  }

  @override
  Future<Schedule> getScheduleDetail(int id) async {
    final response = await _dio.get('/api/v1/schedules/$id');
    return Schedule.fromJson(response.data['data']);
  }

  @override
  Future<Schedule> createSchedule(CreateScheduleRequest request) async {
    final response = await _dio.post('/api/v1/schedules', data: request.toJson());
    return Schedule.fromJson(response.data['data']);
  }

  @override
  Future<Schedule> updateSchedule(int id, Map<String, dynamic> patch) async {
    final response = await _dio.patch('/api/v1/schedules/$id', data: patch);
    return Schedule.fromJson(response.data['data']);
  }

  @override
  Future<void> deleteSchedule(int id) async {
    await _dio.delete('/api/v1/schedules/$id');
  }
}
