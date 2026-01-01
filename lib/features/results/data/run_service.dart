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

  /// Downloads the export for the given run and allows user to save it.
  /// Returns the saved [File] on success, or null on error/cancel.
  Future<File?> exportRun(Run run) async {
    try {
      final response = await _dio.get<List<int>>(
        '/api/v1/runs/${run.id}/export',
        options: Options(responseType: ResponseType.bytes),
      );

      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) return null;

      // Format: [Stress Pilot] Detailed report of run <run id> <yyyyMMdd_HH:mm:ss>.xlsx
      // Note: Windows filenames cannot contain ':', replacing with '.' for valid filename.
      final date = run.createdAt != null
          ? DateTime.parse(run.createdAt!).toLocal()
          : DateTime.now();

      // Use intl pattern if available or manual formatting to ensure correct format
      // Pattern: yyyyMMdd_HH.mm.ss
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
        // User canceled the picker
        return null;
      }

      // Append extension if missing (some platforms might not add it automatically)
      if (!outputFile.toLowerCase().endsWith('.xlsx')) {
        outputFile = '$outputFile.xlsx';
      }

      final finalFile = File(outputFile);
      await finalFile.writeAsBytes(bytes);
      return finalFile;
    } catch (e) {
      // Let caller handle errors / show messages
      rethrow;
    }
  }
}

// Helper extension to safely get first element
