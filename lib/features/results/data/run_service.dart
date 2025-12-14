import 'dart:io';

import 'package:stress_pilot/core/network/http_client.dart';
import 'package:stress_pilot/features/results/domain/models/run.dart';
import 'package:dio/dio.dart';

class RunService {
  final _dio = HttpClient.getInstance();

  Future<Run> getLastRun(int flowId) async {
    final response = await _dio.get('/api/v1/runs/last', queryParameters: {'flowId': flowId});
    return Run.fromJson(response.data);
  }

  Future<List<Run>> getRuns({int? flowId}) async {
    final response = await _dio.get('/api/v1/runs', queryParameters: {if (flowId != null) 'flowId': flowId});
    return (response.data as List).map((e) => Run.fromJson(e)).toList();
  }

  Future<Run> getRun(int runId) async {
    final response = await _dio.get('/api/v1/runs/$runId');
    return Run.fromJson(response.data);
  }

  /// Downloads the export for the given run and writes it to a temporary file.
  /// Returns the saved [File] on success, or null on error.
  Future<File?> exportRun(int runId) async {
    try {
      final response = await _dio.get<List<int>>(
        '/api/v1/runs/$runId/export',
        options: Options(responseType: ResponseType.bytes),
      );

      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) return null;

      final tmpDir = Directory.systemTemp;
      final outFile = File('${tmpDir.path.replaceAll('\\', '/')}/run_${runId}_export');

      // Try to infer extension from content-disposition or default to .zip
      String extension = '.zip';
      final contentDisp = response.headers.map['content-disposition']?.firstOrNull;
      if (contentDisp != null && contentDisp.contains('.')) {
        final idx = contentDisp.lastIndexOf('.');
        extension = contentDisp.substring(idx);
      }

      final finalFile = File(outFile.path + extension);
      await finalFile.writeAsBytes(bytes);
      return finalFile;
    } catch (e) {
      // Let caller handle errors / show messages
      rethrow;
    }
  }
}

// Helper extension to safely get first element
extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
