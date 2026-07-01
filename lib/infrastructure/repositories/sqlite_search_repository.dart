import '../../core/database/local_database.dart';
import '../../domain/repositories/i_search_repository.dart';

class SqliteSearchRepository implements ISearchRepository {
  @override
  Future<void> addRecentSearch(Map<String, dynamic> data) =>
      LocalDatabase.addRecentSearch(data);

  @override
  Future<List<Map<String, dynamic>>> getRecentSearches() =>
      LocalDatabase.getRecentSearches();

  @override
  Future<int> saveLocation(Map<String, dynamic> data) =>
      LocalDatabase.saveLocation(data);

  @override
  Future<List<Map<String, dynamic>>> getSavedLocations() =>
      LocalDatabase.getSavedLocations();

  @override
  Future<int> deleteSavedLocation(String id) =>
      LocalDatabase.deleteSavedLocation(id);
}
