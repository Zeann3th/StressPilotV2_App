import 'package:dio/dio.dart';
import 'package:stress_pilot/core/network/http_client.dart';
import '../../../../core/domain/entities/capability.dart';
import '../../domain/repositories/utility_repository.dart';

class UtilityRepositoryImpl implements UtilityRepository {
  final Dio _dio = HttpClient.getInstance();
  CapabilityDto? _capabilities;

  @override
  Future<String> getSession() async {
    final response = await _dio.get('/api/v1/utilities/session');
    return response.data['data'].toString();
  }

  @override
  Future<CapabilityDto> getCapabilities() async {
    if (_capabilities != null) return _capabilities!;
    final response = await _dio.get('/api/v1/utilities/capabilities');
    _capabilities = CapabilityDto.fromJson(response.data['data']);
    return _capabilities!;
  }
}
