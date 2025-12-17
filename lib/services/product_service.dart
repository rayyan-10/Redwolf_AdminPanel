import '../models/product.dart';
import 'supabase_service.dart';

class ProductService {
  static final ProductService _instance = ProductService._internal();
  factory ProductService() => _instance;
  ProductService._internal();

  final SupabaseService _supabase = SupabaseService();
  final String _tableName = 'products';
  
  // Cache products for instant loading
  List<Product> _cachedProducts = [];
  DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

  // Pre-load products on initialization
  Future<void> preloadProducts() async {
    if (_cachedProducts.isEmpty || 
        _lastFetchTime == null ||
        DateTime.now().difference(_lastFetchTime!) > _cacheDuration) {
      await getProducts(forceRefresh: true);
    }
  }

  // Get all products from database (with caching)
  Future<List<Product>> getProducts({bool forceRefresh = false}) async {
    // Return cached products if available and not expired
    if (!forceRefresh && 
        _cachedProducts.isNotEmpty && 
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheDuration) {
      return List.from(_cachedProducts);
    }
    
    try {
      final response = await _supabase.client
          .from(_tableName)
          .select()
          .order('created_at', ascending: false);

      if (response == null || response.isEmpty) {
        _cachedProducts = [];
        _lastFetchTime = DateTime.now();
        return [];
      }

      final products = (response as List)
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();
      
      // Update cache
      _cachedProducts = products;
      _lastFetchTime = DateTime.now();
      
      return products;
    } catch (e) {
      print('Error fetching products: $e');
      // Return cached products if available, even if expired
      if (_cachedProducts.isNotEmpty) {
        return List.from(_cachedProducts);
      }
      return [];
    }
  }
  
  // Get cached products instantly (no async)
  List<Product> getCachedProducts() {
    return List.from(_cachedProducts);
  }
  
  // Invalidate cache
  void invalidateCache() {
    _cachedProducts = [];
    _lastFetchTime = null;
  }

  // Get filtered products
  Future<List<Product>> getFilteredProducts(String filter) async {
    try {
      final allProducts = await getProducts();
      
      if (filter == 'All Products') {
        return allProducts;
      }
      
      return allProducts.where((p) => p.status == filter).toList();
    } catch (e) {
      print('Error filtering products: $e');
      return [];
    }
  }

  // Get product by ID
  Future<Product?> getProductById(String id) async {
    try {
      final response = await _supabase.client
          .from(_tableName)
          .select()
          .eq('id', id)
          .single();

      if (response == null || response.isEmpty) return null;

      return Product.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error fetching product by ID: $e');
      return null;
    }
  }

  // Add product to database
  Future<String?> addProduct(Product product) async {
    try {
      final response = await _supabase.client
          .from(_tableName)
          .insert(product.toJson())
          .select()
          .single();

      if (response == null || response.isEmpty) return null;

      final responseMap = response as Map<String, dynamic>;
      final productId = responseMap['id'] as String?;
      
      // Update cache - add new product at the beginning
      if (productId != null) {
        final newProduct = Product.fromJson(responseMap);
        _cachedProducts.insert(0, newProduct);
      }
      
      return productId;
    } catch (e) {
      print('Error adding product: $e');
      return null;
    }
  }
  
  // Duplicate/Copy product
  Future<String?> duplicateProduct(Product product) async {
    try {
      // Create a copy of the product with new name
      final duplicatedProduct = Product(
        name: '${product.name} (Copy)',
        category: product.category,
        status: 'Draft', // Always set duplicated products as Draft
        imageUrl: product.imageUrl,
        secondImageUrl: product.secondImageUrl,
        glbFileUrl: product.glbFileUrl,
        description: product.description,
        specifications: product.specifications,
        keyFeatures: product.keyFeatures,
      );
      
      return await addProduct(duplicatedProduct);
    } catch (e) {
      print('Error duplicating product: $e');
      return null;
    }
  }

  // Update product in database
  Future<bool> updateProduct(String id, Product product) async {
    try {
      final productData = product.toJson();
      productData.remove('id'); // Remove id from update data
      productData['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase.client
          .from(_tableName)
          .update(productData)
          .eq('id', id)
          .select()
          .single();

      // Update cache
      final index = _cachedProducts.indexWhere((p) => p.id == id);
      if (index != -1 && response != null) {
        _cachedProducts[index] = Product.fromJson(response as Map<String, dynamic>);
      }

      return true;
    } catch (e) {
      print('Error updating product: $e');
      return false;
    }
  }

  // Delete product from database
  Future<bool> deleteProduct(String id) async {
    try {
      await _supabase.client
          .from(_tableName)
          .delete()
          .eq('id', id);

      // Update cache - remove deleted product
      _cachedProducts.removeWhere((p) => p.id == id);

      return true;
    } catch (e) {
      print('Error deleting product: $e');
      return false;
    }
  }

  // Legacy methods for backward compatibility (now async)
  List<Product> get products => [];
  
  Future<void> addProductSync(Product product) async {
    await addProduct(product);
  }
}
