import 'package:dio/dio.dart';
import 'package:stress_pilot/core/network/http_client.dart';
import '../../domain/models/user_function.dart';
import '../../domain/repositories/function_repository.dart';

class FunctionRepositoryImpl implements FunctionRepository {
  final Dio _dio = HttpClient.getInstance();

  @override
  Future<List<UserFunction>> getAllFunctions() async {
    final response = await _dio.get('/api/v1/functions');

    final data = response.data['data'];
    if (data is Map && data.containsKey('content')) {
      final List<dynamic> content = data['content'];
      return content.map((e) => UserFunction.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  @override
  Future<UserFunction> getFunctionById(int id) async {
    final response = await _dio.get('/api/v1/functions/$id');
    return UserFunction.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<UserFunction> createFunction(UserFunction function) async {
    final response = await _dio.post(
      '/api/v1/functions',
      data: function.toJson(),
    );
    return UserFunction.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<UserFunction> updateFunction(int id, UserFunction function) async {
    final response = await _dio.put(
      '/api/v1/functions/$id',
      data: function.toJson(),
    );
    return UserFunction.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> deleteFunction(int id) async {
    await _dio.delete('/api/v1/functions/$id');
  }
}
