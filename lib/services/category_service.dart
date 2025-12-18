import '../models/category.dart';
import 'supabase_service.dart';

class CategoryService {
  static final CategoryService _instance = CategoryService._internal();
  factory CategoryService() => _instance;
  CategoryService._internal();

  final SupabaseService _supabase = SupabaseService();
  final String _tableName = 'categories';

  List<Category> _cachedCategories = [];
  DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

  // Get categories from database (with caching)
  Future<List<Category>> getCategories({bool forceRefresh = false}) async {
    // Return cached categories if available and not expired
    if (!forceRefresh &&
        _cachedCategories.isNotEmpty &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheDuration) {
      return List.from(_cachedCategories);
    }

    try {
      final response = await _supabase.client
          .from(_tableName)
          .select()
          .order('name', ascending: true);

      // If table is empty, seed default categories
      final responseList = response as List;
      if (responseList.isEmpty) {
        await _insertDefaultCategories();
        final seededResponse = await _supabase.client
            .from(_tableName)
            .select()
            .order('name', ascending: true);
        final categories = (seededResponse as List)
            .map((json) => Category.fromJson(json as Map<String, dynamic>))
            .toList();
        _cachedCategories = categories;
        _lastFetchTime = DateTime.now();
        return categories;
      }

      final categories = responseList
          .map((json) => Category.fromJson(json as Map<String, dynamic>))
          .toList();

      _cachedCategories = categories;
      _lastFetchTime = DateTime.now();
      return categories;
    } catch (e) {
      // On error, fall back to in-memory defaults if cache is empty
      // ignore: avoid_print
      print('Error fetching categories: $e');
      if (_cachedCategories.isNotEmpty) {
        return List.from(_cachedCategories);
      }
      _cachedCategories = _defaultCategories();
      _lastFetchTime = DateTime.now();
      return List.from(_cachedCategories);
    }
  }

  // Get cached categories instantly (no async)
  List<Category> getCachedCategories() {
    return List.from(_cachedCategories);
  }

  // Invalidate cache
  void invalidateCache() {
    _cachedCategories = [];
    _lastFetchTime = null;
  }

  Future<Category?> addCategory(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;

    try {
      // Avoid duplicates – if a category with the same name already exists,
      // return the existing one instead of inserting a new row.
      final existingResponse = await _supabase.client
          .from(_tableName)
          .select()
          .eq('name', trimmed);

      final existingList = existingResponse as List;
      if (existingList.isNotEmpty) {
        final existing =
            Category.fromJson(existingList.first as Map<String, dynamic>);

        final alreadyInCache = _cachedCategories
            .any((c) => c.id == existing.id || c.name == existing.name);
        if (!alreadyInCache) {
          _cachedCategories.add(existing);
        }
        return existing;
      }

      final response = await _supabase.client
          .from(_tableName)
          .insert({'name': trimmed})
          .select()
          .single();
      final data = response as Map<String, dynamic>;
      if (data.isEmpty) return null;

      final category = Category.fromJson(data);
      _cachedCategories.add(category);
      return category;
    } catch (e) {
      // ignore: avoid_print
      print('Error adding category: $e');
      return null;
    }
  }

  Future<bool> updateCategory(String id, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;

    try {
      final response = await _supabase.client
          .from(_tableName)
          .update({'name': trimmed})
          .eq('id', id)
          .select()
          .single();
      final data = response as Map<String, dynamic>;
      if (data.isEmpty) return false;

      final updated = Category.fromJson(data);
      final index = _cachedCategories.indexWhere((c) => c.id == id);
      if (index != -1) {
        _cachedCategories[index] = updated;
      }
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Error updating category: $e');
      return false;
    }
  }

  Future<bool> deleteCategory(String id) async {
    try {
      await _supabase.client.from(_tableName).delete().eq('id', id);
      _cachedCategories.removeWhere((c) => c.id == id);
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Error deleting category: $e');
      return false;
    }
  }

  Future<void> _insertDefaultCategories() async {
    final defaults = ['Wall Mount', 'Portable', 'Touch display'];
    try {
      await _supabase.client.from(_tableName).insert(
            defaults
                .map((name) => {
                      'name': name,
                    })
                .toList(),
          );
    } catch (e) {
      // ignore: avoid_print
      print('Error inserting default categories: $e');
    }
  }

  List<Category> _defaultCategories() {
    return [
      Category(id: 'local_wall_mount', name: 'Wall Mount'),
      Category(id: 'local_portable', name: 'Portable'),
      Category(id: 'local_touch_display', name: 'Touch display'),
    ];
  }
}


