import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:stress_pilot/core/system/logger.dart';

class PluginCapability {
  final String id;
  final String name;
  final String category; // 'endpoint' or 'flow_step'
  final List<String> requiredFields;

  PluginCapability({
    required this.id, 
    required this.name, 
    required this.category, 
    this.requiredFields = const []
  });

  factory PluginCapability.fromJson(Map<String, dynamic> json) {
    return PluginCapability(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      requiredFields: List<String>.from(json['requiredFields'] ?? []),
    );
  }
}

class PluginCapabilityService {
  final List<PluginCapability> _capabilities = [];

  Future<void> initialize() async {
    _capabilities.clear();
    // Add base/default types
    _capabilities.addAll([
      PluginCapability(id: 'HTTP', name: 'HTTP Request', category: 'endpoint'),
      PluginCapability(id: 'GRPC', name: 'gRPC Call', category: 'endpoint'),
      PluginCapability(id: 'JDBC', name: 'JDBC Query', category: 'endpoint'),
      PluginCapability(id: 'JS', name: 'JavaScript Script', category: 'endpoint'),
      PluginCapability(id: 'TCP', name: 'TCP Socket', category: 'endpoint'),
      PluginCapability(id: 'WEBSOCKET', name: 'WebSocket Connection', category: 'endpoint'),
      
      PluginCapability(id: 'ENDPOINT', name: 'Run Endpoint', category: 'flow_step'),
      PluginCapability(id: 'GROUP', name: 'Run Target Group', category: 'flow_step'),
      PluginCapability(id: 'DELAY', name: 'Delay Execution', category: 'flow_step'),
      PluginCapability(id: 'CONDITION', name: 'Conditional Branch', category: 'flow_step'),
    ]);

    try {
      final String home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '/';
      final dir = Directory(p.join(home, '.pilot', 'client', 'types'));
      if (await dir.exists()) {
        final files = await dir.list().where((e) => e.path.endsWith('.json')).toList();
        for (var file in files) {
          try {
            final content = await File(file.path).readAsString();
            final json = jsonDecode(content);
            if (json is List) {
              _capabilities.addAll(json.map((e) => PluginCapability.fromJson(e)));
            } else {
              _capabilities.add(PluginCapability.fromJson(json));
            }
          } catch (e) {
            AppLogger.warning('Failed to parse capability file ${file.path}: $e');
          }
        }
      }
    } catch (e) {
      AppLogger.warning('Failed to load plugin capabilities: $e');
    }
  }

  List<PluginCapability> get endpointTypes {
    final types = _capabilities.where((e) => e.category == 'endpoint').toList();
    // Remove duplicates by ID (last loaded wins, allows overriding defaults)
    final map = {for (var t in types) t.id: t};
    return map.values.toList()..sort((a, b) => a.name.compareTo(b.name));
  }
  
  List<PluginCapability> get flowStepTypes {
    final types = _capabilities.where((e) => e.category == 'flow_step').toList();
    final map = {for (var t in types) t.id: t};
    return map.values.toList()..sort((a, b) => a.name.compareTo(b.name));
  }
}
