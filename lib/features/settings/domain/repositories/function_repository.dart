import '../models/user_function.dart';

abstract class FunctionRepository {
  Future<List<UserFunction>> getAllFunctions();
  Future<UserFunction> getFunctionById(int id);
  Future<UserFunction> createFunction(UserFunction function);
  Future<UserFunction> updateFunction(int id, UserFunction function);
  Future<void> deleteFunction(int id);
}
