abstract class ISearchRepository {
  Future<void> addRecentSearch(Map<String, dynamic> data);
  Future<List<Map<String, dynamic>>> getRecentSearches();
  Future<int> saveLocation(Map<String, dynamic> data);
  Future<List<Map<String, dynamic>>> getSavedLocations();
  Future<int> deleteSavedLocation(String id);
}
