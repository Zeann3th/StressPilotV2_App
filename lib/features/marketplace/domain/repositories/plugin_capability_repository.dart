import '../models/plugin_capability.dart';

abstract class PluginCapabilityRepository {
  Future<void> initialize();
  List<PluginCapability> get endpointTypes;
  List<PluginCapability> get flowStepTypes;
}
