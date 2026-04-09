import 'package:flutter/material.dart';
import '../../domain/models/user_function.dart';
import '../../domain/repositories/function_repository.dart';
import 'package:stress_pilot/core/system/logger.dart';

class FunctionSettingsProvider extends ChangeNotifier {
  final FunctionRepository _repository;

  List<UserFunction> _functions = [];
  bool _isLoading = false;
  String? _error;
  UserFunction? _selectedFunction;

  FunctionSettingsProvider(this._repository);

  List<UserFunction> get functions => _functions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  UserFunction? get selectedFunction => _selectedFunction;

  Future<void> loadFunctions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _functions = await _repository.getAllFunctions();
      if (_selectedFunction != null) {
        final stillExists = _functions.indexWhere((f) => f.id == _selectedFunction!.id);
        if (stillExists != -1) {
          _selectedFunction = _functions[stillExists];
        } else {
          _selectedFunction = null;
        }
      }
    } catch (e) {
      AppLogger.error('Failed to load functions', name: 'FunctionSettingsProvider', error: e);
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectFunction(UserFunction? function) {
    _selectedFunction = function;
    notifyListeners();
  }

  Future<void> saveFunction(UserFunction function) async {
    try {
      UserFunction result;
      if (function.id != null) {
        result = await _repository.updateFunction(function.id!, function);
      } else {
        result = await _repository.createFunction(function);
      }
      await loadFunctions();
      _selectedFunction = result;
      notifyListeners();
    } catch (e) {
      AppLogger.error('Failed to save function', name: 'FunctionSettingsProvider', error: e);
      rethrow;
    }
  }

  Future<void> deleteFunction(int id) async {
    try {
      await _repository.deleteFunction(id);
      if (_selectedFunction?.id == id) {
        _selectedFunction = null;
      }
      await loadFunctions();
    } catch (e) {
      AppLogger.error('Failed to delete function', name: 'FunctionSettingsProvider', error: e);
      rethrow;
    }
  }

  void createNew() {
    _selectedFunction = UserFunction(name: 'New Function', body: '// Enter function definition here\nfunction main(input) {\n  return input;\n}');
    notifyListeners();
  }
}
