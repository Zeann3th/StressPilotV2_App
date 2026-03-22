abstract class SettingRepository {
  Future<Map<String, String>> getAllConfigs();
  Future<String?> getConfigValue(String key);
  Future<void> setConfigValue({
    required String key,
    required String value,
  });
}
