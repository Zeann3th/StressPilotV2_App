import 'dart:io';

import 'package:stress_pilot/core/network/http_client.dart';
import 'package:stress_pilot/features/results/domain/models/run.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

class RunService {
  final _dio = HttpClient.getInstance();

  Future<Run> getLastRun(int flowId) async {
    final response = await _dio.get(
      '/api/v1/runs/last',
      queryParameters: {'flowId': flowId},
    );
    return Run.fromJson(response.data);
  }

  Future<List<Run>> getRuns({int? flowId}) async {
    final response = await _dio.get(
      '/api/v1/runs',
      queryParameters: {if (flowId != null) 'flowId': flowId},
    );
    return (response.data as List).map((e) => Run.fromJson(e)).toList();
  }

  Future<Run> getRun(int runId) async {
    final response = await _dio.get('/api/v1/runs/$runId');
    return Run.fromJson(response.data);
  }

  
  
  Future<File?> exportRun(Run run) async {
    try {
      final response = await _dio.get<List<int>>(
        '/api/v1/runs/${run.id}/export',
        
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(minutes: 2),
        ),
      );

      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) return null;

      final date = run.startedAt.toLocal();

      final dateStr =
          '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}_'
          '${date.hour.toString().padLeft(2, '0')}.${date.minute.toString().padLeft(2, '0')}.${date.second.toString().padLeft(2, '0')}';

      final fileName =
          '[Stress Pilot] Detailed report of run ${run.id} $dateStr.xlsx';

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Run Report',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (outputFile == null) {
        return null;
      }

      if (!outputFile.toLowerCase().endsWith('.xlsx')) {
        outputFile = '$outputFile.xlsx';
      }

      final finalFile = File(outputFile);
      await finalFile.writeAsBytes(bytes);
      return finalFile;
    } catch (e) {
      rethrow;
    }
  }
}
