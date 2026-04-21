import 'package:flutter/material.dart';

enum WorkspaceTabType { flow, endpoint }

class WorkspaceTab {
  final String id;
  final String name;
  final WorkspaceTabType type;
  final dynamic data;

  WorkspaceTab({
    required this.id,
    required this.name,
    required this.type,
    this.data,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkspaceTab && runtimeType == other.runtimeType && id == other.id && type == other.type;

  @override
  int get hashCode => id.hashCode ^ type.hashCode;
}

class WorkspaceTabProvider with ChangeNotifier {
  final List<WorkspaceTab> _tabs = [];
  WorkspaceTab? _activeTab;

  List<WorkspaceTab> get tabs => List.unmodifiable(_tabs);
  WorkspaceTab? get activeTab => _activeTab;

  void openTab(WorkspaceTab tab) {
    final index = _tabs.indexWhere((t) => t.id == tab.id && t.type == tab.type);
    if (index == -1) {
      _tabs.add(tab);
    }
    _activeTab = tab;
    notifyListeners();
  }

  void closeTab(WorkspaceTab tab) {
    final index = _tabs.indexWhere((t) => t.id == tab.id && t.type == tab.type);
    if (index != -1) {
      _tabs.removeAt(index);
      if (_activeTab == tab) {
        _activeTab = _tabs.isNotEmpty ? _tabs.last : null;
      }
      notifyListeners();
    }
  }

  void selectTab(WorkspaceTab tab) {
    _activeTab = tab;
    notifyListeners();
  }

  void clear() {
    _tabs.clear();
    _activeTab = null;
    notifyListeners();
  }
}
