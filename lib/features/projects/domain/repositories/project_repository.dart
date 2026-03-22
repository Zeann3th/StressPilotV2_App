import 'package:stress_pilot/features/shared/domain/models/paged_response.dart';
import 'package:stress_pilot/features/projects/domain/models/project.dart';

abstract class ProjectRepository {
  Future<PagedResponse<Project>> getProjects({String? name, int page = 0, int size = 20});
  Future<Project> getProjectDetail(int projectId);
  Future<Project> createProject({required String name, String? description, int? environmentId});
  Future<Project> updateProject({required int projectId, String? name, String? description, int? environmentId});
  Future<void> deleteProject(int projectId);
  Future<void> exportProject(int projectId, String savePath);
  Future<Project> importProject(String filePath);
}
