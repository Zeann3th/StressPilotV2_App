import 'package:dio/dio.dart';
import 'package:stress_pilot/core/network/http_client.dart';
import 'package:stress_pilot/features/shared/domain/models/paged_response.dart';
import 'package:stress_pilot/features/projects/domain/models/project.dart';
import '../../domain/repositories/project_repository.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  final Dio _dio = HttpClient.getInstance();

  @override
  Future<PagedResponse<Project>> getProjects({
    String? name,
    int page = 0,
    int size = 20,
  }) async {
    final response = await _dio.get(
      '/api/v1/projects',
      queryParameters: {
        if (name != null && name.isNotEmpty) 'name': name,
        'page': page,
        'size': size,
      },
    );

    return PagedResponse.fromJson(
      response.data['data'],
          (json) => Project.fromJson(json),
    );
  }

  @override
  Future<Project> getProjectDetail(int projectId) async {
    final response = await _dio.get('/api/v1/projects/$projectId');
    return Project.fromJson(response.data['data']);
  }

  @override
  Future<Project> createProject({
    required String name,
    String? description,
    int? environmentId,
  }) async {
    final body = {
      'name': name,
      'description': description,
      'environmentId': environmentId,
    };

    final response = await _dio.post('/api/v1/projects', data: body);
    return Project.fromJson(response.data['data']);
  }

  @override
  Future<Project> updateProject({
    required int projectId,
    String? name,
    String? description,
    int? environmentId,
  }) async {
    final body = {
      'name': ?name,
      'description': ?description,
      'environmentId': ?environmentId,
    };

    final response = await _dio.patch('/api/v1/projects/$projectId', data: body);
    return Project.fromJson(response.data['data']);
  }

  @override
  Future<void> deleteProject(int projectId) async {
    await _dio.delete('/api/v1/projects/$projectId');
  }

  @override
  Future<void> exportProject(int projectId, String savePath) async {
    await _dio.download(
      '/api/v1/projects/$projectId/export',
      savePath,
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: false,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
  }

  @override
  Future<Project> importProject(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filePath,
        filename: filePath.split('/').last,
      ),
    });

    final response = await _dio.post(
      '/api/v1/projects/import',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );

    return Project.fromJson(response.data['data']);
  }
}
