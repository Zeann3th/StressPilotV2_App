import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stress_pilot/core/models/paged_response.dart';
import 'package:stress_pilot/features/projects/data/project_service.dart';
import 'package:stress_pilot/features/projects/domain/project.dart';

class ProjectProvider extends ChangeNotifier {
  final ProjectService _projectService = ProjectService();

  List<Project> _projects = [];
  Project? _selectedProject;
  bool _isLoading = false;
  String? _error;

  List<Project> get projects => _projects;
  Project? get selectedProject => _selectedProject;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasSelectedProject => _selectedProject != null;

  static const String _selectedProjectKey = 'selected_project_json';

  Future<void> initialize() async {
    await _loadSelectedProject();
  }

  Future<void> loadProjects({String? searchName}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final PagedResponse<Project> response = await _projectService.getProjects(
        name: searchName,
        page: 0,
        size: 20,
      );
      _projects = response.content;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _projects = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectProject(Project project) async {
    _selectedProject = project;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(project.toJson());
    await prefs.setString(_selectedProjectKey, jsonString);
  }

  Future<void> clearProject() async {
    _selectedProject = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selectedProjectKey);
  }

  Future<void> _loadSelectedProject() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_selectedProjectKey);

    if (jsonString != null) {
      try {
        final Map<String, dynamic> json = jsonDecode(jsonString);
        _selectedProject = Project.fromJson(json);
        notifyListeners();
      } catch (e) {
        await prefs.remove(_selectedProjectKey);
      }
    }
  }

  Future<Project> createProject({
    required String name,
    String? description,
    int? environmentId,
  }) async {
    try {
      final project = await _projectService.createProject(
        name: name,
        description: description,
        environmentId: environmentId,
      );
      _projects.insert(0, project);
      notifyListeners();
      return project;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<Project> updateProject({
    required int projectId,
    String? name,
    String? description,
    int? environmentId,
  }) async {
    try {
      final updated = await _projectService.updateProject(
        projectId: projectId,
        name: name,
        description: description,
        environmentId: environmentId,
      );

      final index = _projects.indexWhere((p) => p.id == projectId);
      if (index != -1) {
        _projects[index] = updated;
      }

      if (_selectedProject?.id == projectId) {
        _selectedProject = updated;

        final prefs = await SharedPreferences.getInstance();
        final jsonString = jsonEncode(updated.toJson());
        await prefs.setString(_selectedProjectKey, jsonString);
      }

      notifyListeners();
      return updated;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteProject(int projectId) async {
    try {
      await _projectService.deleteProject(projectId);
      _projects.removeWhere((p) => p.id == projectId);

      if (_selectedProject?.id == projectId) {
        await clearProject();
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> exportProject(int projectId, String projectName) async {
    try {
      
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Project',
        fileName: '${projectName.replaceAll(' ', '_')}_export.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null) {
        
        return;
      }

      await _projectService.exportProject(projectId, result);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<Project> importProject() async {
    try {
      
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Import Project',
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        
        throw Exception('No file selected');
      }

      final filePath = result.files.first.path;
      if (filePath == null) {
        throw Exception('Invalid file path');
      }

      final project = await _projectService.importProject(filePath);
      _projects.insert(0, project);
      _error = null;
      notifyListeners();
      return project;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}