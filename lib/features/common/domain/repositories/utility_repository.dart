import '../../../../core/domain/entities/capability.dart';

abstract class UtilityRepository {
  Future<String> getSession();
  Future<CapabilityDto> getCapabilities();
}
