import '../../core/database/local_database.dart';
import '../../domain/repositories/i_rider_settings_repository.dart';

class SqliteRiderSettingsRepository implements IRiderSettingsRepository {
  @override
  Future<String?> get(String key) => LocalDatabase.getRiderSetting(key);

  @override
  Future<void> set(String key, String value) =>
      LocalDatabase.setRiderSetting(key, value);
}
