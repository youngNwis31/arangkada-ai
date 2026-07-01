abstract class IRiderSettingsRepository {
  Future<String?> get(String key);
  Future<void> set(String key, String value);
}
