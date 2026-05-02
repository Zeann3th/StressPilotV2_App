import 'dart:io';
import 'package:stress_pilot/features/results/domain/models/run.dart';

abstract class RunRepository {
  Future<Run> getLastRun(int flowId);
  Future<List<Run>> getRuns({int? flowId});
  Future<Run> getRun(String runId);
  Future<File?> exportRun(Run run);
  Future<void> interruptRun(String runId);
}
