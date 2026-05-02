import 'package:flutter/material.dart';
import 'package:stress_pilot/core/system/logger.dart';
import '../../domain/models/schedule.dart';
import '../../domain/repositories/schedule_repository.dart';

class SchedulingProvider extends ChangeNotifier {
  final ScheduleRepository _repository;

  List<Schedule> _schedules = [];
  bool _isLoading = false;
  String? _error;
  Schedule? _selectedSchedule;

  SchedulingProvider(this._repository);

  List<Schedule> get schedules => _schedules;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Schedule? get selectedSchedule => _selectedSchedule;

  Future<void> loadSchedules() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final paged = await _repository.getSchedules(page: 0, size: 100);
      _schedules = paged.content;

      if (_selectedSchedule != null) {
        final stillExists = _schedules.indexWhere((s) => s.id == _selectedSchedule!.id);
        if (stillExists != -1) {
          _selectedSchedule = _schedules[stillExists];
        } else {
          _selectedSchedule = null;
        }
      }
    } catch (e) {
      AppLogger.error('Failed to load schedules', name: 'SchedulingProvider', error: e);
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectSchedule(Schedule? schedule) {
    _selectedSchedule = schedule;
    notifyListeners();
  }

  Future<void> saveSchedule(Schedule schedule, {CreateScheduleRequest? createRequest}) async {
    try {
      Schedule result;
      if (createRequest != null) {
        result = await _repository.createSchedule(createRequest);
      } else {
        final patch = {
          'flowId': schedule.flowId,
          'quartzExpr': schedule.quartzExpr,
          'threads': schedule.threads,
          'duration': schedule.duration,
          'rampUp': schedule.rampUp,
          'enabled': schedule.enabled,
        };
        result = await _repository.updateSchedule(schedule.id, patch);
      }
      await loadSchedules();
      _selectedSchedule = result;
      notifyListeners();
    } catch (e) {
      AppLogger.error('Failed to save schedule', name: 'SchedulingProvider', error: e);
      rethrow;
    }
  }

  Future<void> deleteSchedule(int id) async {
    try {
      await _repository.deleteSchedule(id);
      if (_selectedSchedule?.id == id) {
        _selectedSchedule = null;
      }
      await loadSchedules();
    } catch (e) {
      AppLogger.error('Failed to delete schedule', name: 'SchedulingProvider', error: e);
      rethrow;
    }
  }

  void createNew() {

    _selectedSchedule = null;
    notifyListeners();
  }
}
