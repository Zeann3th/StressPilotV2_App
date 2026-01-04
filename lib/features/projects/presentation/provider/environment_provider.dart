import 'package:flutter/material.dart';
import '../../data/environment_service.dart';
import '../../domain/environment_variable.dart';

class EnvironmentProvider extends ChangeNotifier {
  final EnvironmentService _service = EnvironmentService();

  List<EnvironmentVariable> _variables = [];
  List<EnvironmentVariable> _originalVariables = [];
  bool _isLoading = false;
  String? _error;
  int _tempIdCounter = 0;

  List<EnvironmentVariable> get variables => _variables;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasChanges => _calculateHasChanges();

  Future<void> loadVariables(int environmentId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final vars = await _service.getVariables(environmentId);
      _variables = List.from(vars);
      
      _originalVariables = vars.map((e) => e.copyWith()).toList();
    } catch (e) {
      _error = e.toString();
      _variables = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addVariable() {
    _tempIdCounter--;
    final newVar = EnvironmentVariable(
      id: _tempIdCounter,
      environmentId: 0, 
      key: '',
      value: '',
      isActive: true,
    );
    _variables.add(newVar);
    notifyListeners();
  }

  void updateVariable(int index, {String? key, String? value, bool? isActive}) {
    if (index < 0 || index >= _variables.length) return;

    final old = _variables[index];
    _variables[index] = old.copyWith(
      key: key,
      value: value,
      isActive: isActive,
    );
    notifyListeners();
  }

  void removeVariable(int index) {
    if (index < 0 || index >= _variables.length) return;
    _variables.removeAt(index);
    notifyListeners();
  }

  Future<void> saveChanges(int environmentId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final added = <Map<String, dynamic>>[];
      final updated = <Map<String, dynamic>>[];
      final removed = <int>[];

      
      for (final v in _variables) {
        if (v.id <= 0) {
          added.add({'key': v.key, 'value': v.value});
        } else {
          
          final original = _originalVariables.firstWhere(
            (o) => o.id == v.id,
            orElse: () => v, 
          );

          if (original.key != v.key ||
              original.value != v.value ||
              original.isActive != v.isActive) {
            updated.add({
              'id': v.id,
              'key': v.key,
              'value': v.value,
              'isActive': v.isActive,
            });
          }
        }
      }

      
      final currentIds = _variables.map((v) => v.id).toSet();
      for (final original in _originalVariables) {
        if (!currentIds.contains(original.id)) {
          removed.add(original.id);
        }
      }

      if (added.isEmpty && updated.isEmpty && removed.isEmpty) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      await _service.updateVariables(
        environmentId: environmentId,
        added: added,
        updated: updated,
        removed: removed,
      );

      
      await loadVariables(environmentId);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  bool _calculateHasChanges() {
    if (_variables.length != _originalVariables.length) return true;

    
    
    if (_variables.any((v) => v.id <= 0)) return true;

    
    final currentIds = _variables.map((v) => v.id).toSet();
    if (_originalVariables.any((v) => !currentIds.contains(v.id))) return true;

    
    for (final v in _variables) {
      final original = _originalVariables.firstWhere((o) => o.id == v.id);
      if (original.key != v.key ||
          original.value != v.value ||
          original.isActive != v.isActive) {
        return true;
      }
    }

    return false;
  }
}
