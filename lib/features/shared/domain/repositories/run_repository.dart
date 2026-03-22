import 'dart:io';
import 'package:stress_pilot/features/shared/domain/models/run.dart';

abstract class RunRepository {
  Future<Run> getLastRun(int flowId);
  Future<List<Run>> getRuns({int? flowId});
  Future<Run> getRun(int runId);
  Future<File?> exportRun(Run run);
  Future<void> interruptRun(int runId);
}
