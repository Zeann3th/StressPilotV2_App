import 'package:stress_pilot/features/shared/domain/models/capability.dart';

abstract class UtilityRepository {
  Future<String> getSession();
  Future<CapabilityDto> getCapabilities();
}
