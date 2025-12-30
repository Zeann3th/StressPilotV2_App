import 'package:dio/dio.dart';
import 'package:stress_pilot/core/network/http_client.dart';
import 'package:stress_pilot/core/models/paged_response.dart';
import '../domain/project.dart';

class ProjectService {
  final Dio _dio = HttpClient.getInstance();

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
      response.data,
          (json) => Project.fromJson(json),
    );
  }

  Future<Project> getProjectDetail(int projectId) async {
    final response = await _dio.get('/api/v1/projects/$projectId');
    return Project.fromJson(response.data);
  }

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
    return Project.fromJson(response.data);
  }

  Future<Project> updateProject({
    required int projectId,
    String? name,
    String? description,
    int? environmentId,
  }) async {
    final body = {
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (environmentId != null) 'environmentId': environmentId,
    };

    final response = await _dio.patch('/api/v1/projects/$projectId', data: body);
    return Project.fromJson(response.data);
  }

  Future<void> deleteProject(int projectId) async {
    await _dio.delete('/api/v1/projects/$projectId');
  }

  Future<void> exportProject(int projectId, String savePath) async {
    await _dio.download(
      '/api/v1/projects/$projectId/export',
      savePath,
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: false,
      ),
    );
  }

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
      ),
    );

    return Project.fromJson(response.data);
  }
}