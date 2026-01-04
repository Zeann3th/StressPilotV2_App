import 'package:dio/dio.dart';
import 'package:stress_pilot/core/config/app_config.dart';
import 'package:stress_pilot/core/system/logger.dart';
import 'package:stress_pilot/features/marketplace/domain/models/nexus_artifact.dart';

class NexusService {
  final Dio _dio;

  NexusService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: AppConfig.nexusBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

  Future<List<NexusArtifact>> searchPlugins(String query) async {
    try {
      final Map<String, dynamic> queryParams = {
        'repository': 'maven-releases', // Target specific repo
        'format': 'maven2',
      };

      // If query is not empty, use the keyword search 'q'
      if (query.isNotEmpty) {
        queryParams['q'] = query;
      } else {
        // If empty, maybe sort by version or fetch recent (Nexus API sort is limited)
        queryParams['sort'] = 'version';
      }

      // We use the /search endpoint (Components) instead of /search/assets
      // This groups the .jar, .pom, .javadoc together so we get 1 result per plugin version
      final response = await _dio.get(
        '/service/rest/v1/search',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data['items'] != null) {
        final items = response.data['items'] as List;

        // Map to artifacts and filter out any that don't have a valid JAR link
        return items
            .map((e) => NexusArtifact.fromJson(e as Map<String, dynamic>))
            .where((artifact) => artifact.downloadUrl != null)
            .toList();
      }
      return [];
    } catch (e, stackTrace) {
      AppLogger.error(
        'Nexus Search Error: $e',
        name: 'NexusService',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }
}
