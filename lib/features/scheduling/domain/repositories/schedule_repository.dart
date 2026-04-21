import 'package:stress_pilot/features/shared/domain/models/paged_response.dart';
import '../models/schedule.dart';

abstract class ScheduleRepository {
  Future<PagedResponse<Schedule>> getSchedules({
    int page = 0,
    int size = 20,
  });

  Future<Schedule> getScheduleDetail(int id);

  Future<Schedule> createSchedule(CreateScheduleRequest request);

  Future<Schedule> updateSchedule(int id, Map<String, dynamic> patch);

  Future<void> deleteSchedule(int id);
}
