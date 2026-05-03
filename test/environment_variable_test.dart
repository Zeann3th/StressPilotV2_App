import 'package:flutter_test/flutter_test.dart';
import 'package:stress_pilot/features/environments/domain/environment_variable.dart';

void main() {
  group('EnvironmentVariable', () {
    test('fromJson should handle "active" key from backend', () {
      final json = {
        'id': 1,
        'environmentId': 10,
        'key': 'MY_VAR',
        'value': 'my_value',
        'active': false,
      };

      final variable = EnvironmentVariable.fromJson(json);

      expect(variable.isActive, isFalse);
      expect(variable.key, 'MY_VAR');
      expect(variable.value, 'my_value');
    });

    test('fromJson should fall back to "isActive" if "active" is missing', () {
      final json = {
        'id': 1,
        'environmentId': 10,
        'key': 'MY_VAR',
        'value': 'my_value',
        'isActive': false,
      };

      final variable = EnvironmentVariable.fromJson(json);

      expect(variable.isActive, isFalse);
    });

    test('toJson should output "active" key for backend compatibility', () {
      final variable = EnvironmentVariable(
        id: 1,
        environmentId: 10,
        key: 'MY_VAR',
        value: 'my_value',
        isActive: false,
      );

      final json = variable.toJson();

      expect(json['active'], isFalse);
      expect(json.containsKey('isActive'), isFalse);
    });
  });
}