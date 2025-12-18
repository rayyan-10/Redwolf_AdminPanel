import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/sidebar.dart';
import '../widgets/footer.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../widgets/manage_category_dialog.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'All Products';
  final ProductService _productService = ProductService();
  List<Product> _allProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    // Load cached products instantly (no delay)
    _loadProductsInstantly();
    // Refresh in background without showing loading
    _loadProductsSilently();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh products when page becomes visible (e.g., when navigating back from add product)
    // Force refresh to get latest products
    _refreshProducts();
  }
  
  // Load cached products instantly (no loading indicator, no delay)
  void _loadProductsInstantly() {
    final cachedProducts = _productService.getCachedProducts();
    setState(() {
      _allProducts = cachedProducts;
      _isLoading = false; // Never show loading if we have cached data
    });
  }
  
  // Load products silently in background (no loading indicator)
  Future<void> _loadProductsSilently() async {
    if (!mounted) return;
    
    try {
      final products = await _productService.getProducts(forceRefresh: false);
      if (mounted) {
        setState(() {
          _allProducts = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Silently fail - keep showing cached products
      if (mounted && _allProducts.isEmpty) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // Force refresh products (used when navigating back from add product)
  Future<void> _refreshProducts() async {
    if (!mounted) return;
    
    try {
      final products = await _productService.getProducts(forceRefresh: true);
      if (mounted) {
        setState(() {
          _allProducts = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged() {
    setState(() {}); // Trigger rebuild when search text changes
  }

  Future<void> _loadProducts({bool forceRefresh = false}) async {
    if (!mounted) return;
    
    // Only show loading if we don't have cached products
    if (_allProducts.isEmpty || forceRefresh) {
      setState(() {
        _isLoading = true;
      });
    }
    
    try {
      final products = await _productService.getProducts(forceRefresh: forceRefresh);
      if (mounted) {
        setState(() {
          _allProducts = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading products: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  List<Product> _getFilteredAndSearchedProducts() {
    String searchQuery = _searchController.text.toLowerCase().trim();
    
    // First apply status filter
    List<Product> filtered;
    if (_selectedFilter == 'All Products') {
      filtered = List.from(_allProducts);
    } else {
      filtered = _allProducts.where((p) => p.status == _selectedFilter).toList();
    }
    
    // Then apply search filter if there's a search query
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((product) {
        return product.name.toLowerCase().contains(searchQuery) ||
               product.category.toLowerCase().contains(searchQuery) ||
               (product.description?.toLowerCase().contains(searchQuery) ?? false);
      }).toList();
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;
        
        if (isMobile) {
          return Scaffold(
            backgroundColor: const Color(0xFFF9FAFB),
            drawer: Drawer(
              child: Sidebar(currentRoute: '/products'),
            ),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Color(0xFF111827)),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              title: _buildLogo(),
            ),
            body: _buildContent(context, constraints),
          );
        }
        
        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          body: Row(
            children: [
              const Sidebar(currentRoute: '/products'),
              Expanded(
                child: _buildContent(context, constraints),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, BoxConstraints constraints) {
    final isTablet = constraints.maxWidth >= 768 && constraints.maxWidth < 1024;
    final filteredProducts = _getFilteredAndSearchedProducts();
    
    return Column(
      children: [
        // Header - static at top, aligned with sidebar logo (24px from top)
        _buildHeader(context, constraints),
        // Products Table - scrollable content below header
        Expanded(
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: isTablet ? 16 : 24,
                    right: isTablet ? 16 : 24,
                    top: 20,
                    bottom: 100,
                  ),
                  child: _isLoading && _allProducts.isEmpty
                      ? Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                          ),
                          padding: const EdgeInsets.all(40.0),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : _buildProductsTable(constraints, filteredProducts),
                ),
              ),
              const Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Footer(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, BoxConstraints constraints) {
    final isMobile = constraints.maxWidth < 768;
    final isTablet = constraints.maxWidth >= 768 && constraints.maxWidth < 1024;
    
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Products',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}), // Update on search
            decoration: InputDecoration(
              hintText: 'Search...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterDropdown(width: double.infinity),
              SizedBox(
                width: double.infinity,
                child: _buildButton('Manage Category', isSecondary: true),
              ),
              SizedBox(
                width: double.infinity,
                child: _buildButton('Add product', isSecondary: false),
              ),
            ],
          ),
        ],
      );
    }
    
    // Tablet layout - more compact
    if (isTablet) {
      return Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Products',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const Spacer(),
                  _buildButton('Add product', isSecondary: false),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}), // Update on search
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF), size: 20),
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildFilterDropdown(),
                  const SizedBox(width: 12),
                  _buildButton('Manage Category', isSecondary: true),
                ],
              ),
            ],
          ),
        ),
      );
    }
    
    // Desktop layout
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Products Title
            const Text(
              'Products',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(width: 24),
            // Search Bar
            Expanded(
              child: SizedBox(
                height: 40,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF), size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Filter Dropdown
            _buildFilterDropdown(),
            const SizedBox(width: 12),
            // Manage Category Button
            _buildButton('Manage Category', isSecondary: true),
            const SizedBox(width: 12),
            // Add Product Button
            _buildButton('Add product', isSecondary: false),  
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown({double? width}) {
    return SizedBox(
      width: width ?? 150,
      height: 40,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: DropdownButton<String>(
          value: _selectedFilter,
          isExpanded: true,
          underline: const SizedBox(),
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF9CA3AF), size: 20),
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF374151),
          ),
          items: ['All Products', 'Published', 'Draft']
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(
                      item,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedFilter = value;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildButton(String text, {required bool isSecondary}) {
    return SizedBox(
      height: 40,
      child: ElevatedButton(
        onPressed: () async {
          if (text.contains('Add product')) {
            await context.push('/products/add');
            if (!mounted) return;
            await _loadProducts(forceRefresh: true);
          } else if (text.contains('Manage Category')) {
            await showDialog(
              context: context,
              barrierDismissible: true,
              builder: (dialogContext) {
                return ManageCategoryDialog(
                  onCategoriesChanged: () {
                    // Categories are synced with AddProductPage via CategoryService
                  },
                );
              },
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSecondary ? Colors.white : const Color(0xFFDC2626),
          foregroundColor: isSecondary ? const Color(0xFF374151) : Colors.white,
          side: isSecondary
              ? const BorderSide(color: Color(0xFFE5E7EB))
              : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          minimumSize: Size.zero,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isSecondary && (text.contains('Add product') || text.contains('Add'))) ...[
              const Icon(Icons.add, size: 18, color: Colors.white),
              const SizedBox(width: 4),
            ],
            Text(
              text.replaceAll('+ ', '').replaceAll('+', ''),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsTable(BoxConstraints constraints, List<Product> products) {
    final isMobile = constraints.maxWidth < 768;
    final isTablet = constraints.maxWidth >= 768 && constraints.maxWidth < 1024;
    
    if (isMobile) {
      return Column(
        children: products.asMap().entries.map((entry) {
          final index = entry.key;
          final product = entry.value;
          return _buildMobileProductCard(product, index, products);
        }).toList(),
      );
    }
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: LayoutBuilder(
        builder: (context, tableConstraints) {
          final availableWidth = tableConstraints.maxWidth;
          // Adjust column spacing and widths for tablet
          final columnSpacing = isTablet ? 16.0 : 32.0;
          final productInfoWidth = isTablet ? (availableWidth - 48) * 0.40 : (availableWidth - 96) * 0.45;
          final categoryWidth = isTablet ? (availableWidth - 48) * 0.20 : (availableWidth - 96) * 0.20;
          final statusWidth = isTablet ? (availableWidth - 48) * 0.15 : (availableWidth - 96) * 0.15;
          final actionWidth = isTablet ? (availableWidth - 48) * 0.25 : (availableWidth - 96) * 0.20;
          
          return DataTable(
            headingRowHeight: 48,
            dataRowMinHeight: 80,
            dataRowMaxHeight: 80,
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
            dataRowColor: WidgetStateProperty.resolveWith((states) {
              return Colors.white;
            }),
            columnSpacing: columnSpacing,
            columns: [
              DataColumn(
                label: SizedBox(
                  width: productInfoWidth,
                  child: _buildDataColumnLabel('Product info'),
                ),
                onSort: (columnIndex, ascending) {
                  // Sorting functionality can be implemented here
                },
              ),
              DataColumn(
                label: SizedBox(
                  width: categoryWidth,
                  child: _buildDataColumnLabel('Category'),
                ),
                onSort: (columnIndex, ascending) {
                  // Sorting functionality can be implemented here
                },
              ),
              DataColumn(
                label: SizedBox(
                  width: statusWidth,
                  child: _buildDataColumnLabel('Status'),
                ),
                onSort: (columnIndex, ascending) {
                  // Sorting functionality can be implemented here
                },
              ),
              DataColumn(
                label: SizedBox(
                  width: actionWidth,
                  child: const Text(
                    'Action',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
            ],
            rows: products.asMap().entries.map((entry) {
              final index = entry.key;
              final product = entry.value;
              return _buildDataRow(product, availableWidth, isTablet, index);
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildMobileProductCard(Product product, int index, List<Product> productsList) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildProductImage(product, width: 60, height: 60),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.category,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusChip(product.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: _buildActionIcons(product, index),
          ),
        ],
      ),
    );
  }

  Widget _buildDataColumnLabel(String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(width: 4),
        const Icon(
          Icons.unfold_more,
          size: 16,
          color: Color(0xFF9CA3AF),
        ),
      ],
    );
  }

  DataRow _buildDataRow(Product product, double availableWidth, bool isTablet, int index) {
    final productInfoWidth = isTablet ? (availableWidth - 48) * 0.40 : (availableWidth - 96) * 0.45;
    final categoryWidth = isTablet ? (availableWidth - 48) * 0.20 : (availableWidth - 96) * 0.20;
    final actionWidth = isTablet ? (availableWidth - 48) * 0.25 : (availableWidth - 96) * 0.20;
    
    return DataRow(
      cells: [
        DataCell(
          SizedBox(
            width: productInfoWidth,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  _buildProductImage(
                    product,
                    width: isTablet ? 50 : 60,
                    height: isTablet ? 50 : 60,
                  ),
                  SizedBox(width: isTablet ? 8 : 12),
                  Expanded(
                    child: Text(
                      product.name,
                      style: TextStyle(
                        fontSize: isTablet ? 13 : 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF111827),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: categoryWidth,
            child: Text(
              product.category,
              style: TextStyle(
                fontSize: isTablet ? 13 : 14,
                color: const Color(0xFF374151),
              ),
            ),
          ),
        ),
        DataCell(
          Align(
            alignment: Alignment.centerLeft,
            child: _buildStatusChip(product.status),
          ),
        ),
        DataCell(
          SizedBox(
            width: actionWidth,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: _buildActionIcons(product, index),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    final isPublished = status == 'Published';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPublished
            ? const Color(0xFFD1FAE5)
            : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isPublished
              ? const Color(0xFF065F46)
              : const Color(0xFF92400E),
        ),
      ),
    );
  }

  List<Widget> _buildActionIcons(Product product, int productIndex) {
    return [
      IconButton(
        icon: const Icon(Icons.visibility_outlined, size: 18),
        color: const Color(0xFF6B7280),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(
          minWidth: 28,
          minHeight: 28,
        ),
        onPressed: () {},
      ),
      IconButton(
        icon: const Icon(Icons.copy_outlined, size: 18),
        color: const Color(0xFF6B7280),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(
          minWidth: 28,
          minHeight: 28,
        ),
        onPressed: () => _duplicateProduct(product),
      ),
      IconButton(
        icon: const Icon(Icons.edit_outlined, size: 18),
        color: const Color(0xFF2563EB),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(
          minWidth: 28,
          minHeight: 28,
        ),
        onPressed: () {
          // Navigate to edit page with product data
          context.push('/products/add', extra: product).then((_) {
            // Reload products after editing
            if (mounted) {
              _loadProducts(forceRefresh: true);
            }
          });
        },
      ),
      IconButton(
        icon: const Icon(Icons.delete_outline, size: 18),
        color: const Color(0xFFDC2626),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(
          minWidth: 28,
          minHeight: 28,
        ),
        onPressed: () {
          _showDeleteDialog(product, productIndex);
        },
      ),
    ];
  }

  Future<void> _duplicateProduct(Product product) async {
    if (product.id == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Product ID not found'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final productId = await _productService.duplicateProduct(product);
      
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        if (productId != null) {
          // Reload products to show the new duplicate
          await _loadProducts(forceRefresh: true);
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product duplicated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error duplicating product'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteDialog(Product product, int productIndex) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Product'),
          content: Text('Are you sure you want to delete "${product.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (product.id == null) {
                  Navigator.of(context).pop();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Error: Product ID not found'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  return;
                }

                final success = await _productService.deleteProduct(product.id!);
                Navigator.of(context).pop();
                
                if (success) {
                  // Reload products from database
                  await _loadProducts(forceRefresh: true);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Product deleted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Error deleting product'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductImage(Product product, {double? width, double? height}) {
    final imgWidth = width ?? 60;
    final imgHeight = height ?? 60;
    
    // If product has image bytes or data URL, use those (for local/unsaved products)
    if (product.imageDataUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          product.imageDataUrl!,
          width: imgWidth,
          height: imgHeight,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: imgWidth,
              height: imgHeight,
              color: const Color(0xFFE5E7EB),
              child: const Icon(Icons.image, color: Color(0xFF9CA3AF)),
            );
          },
        ),
      );
    } else if (product.imageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          Uint8List.fromList(product.imageBytes!),
          width: imgWidth,
          height: imgHeight,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: imgWidth,
              height: imgHeight,
              color: const Color(0xFFE5E7EB),
              child: const Icon(Icons.image, color: Color(0xFF9CA3AF)),
            );
          },
        ),
      );
    } else if (product.imageUrl.isNotEmpty) {
      // Check if imageUrl is a network URL (from Supabase storage)
      if (product.imageUrl.startsWith('http://') || product.imageUrl.startsWith('https://')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            product.imageUrl,
            width: imgWidth,
            height: imgHeight,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: imgWidth,
                height: imgHeight,
                color: const Color(0xFFE5E7EB),
                child: const Icon(Icons.image, color: Color(0xFF9CA3AF)),
              );
            },
          ),
        );
      } else {
        // Use asset image (for default/placeholder images)
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            product.imageUrl,
            width: imgWidth,
            height: imgHeight,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: imgWidth,
                height: imgHeight,
                color: const Color(0xFFE5E7EB),
                child: const Icon(Icons.image, color: Color(0xFF9CA3AF)),
              );
            },
          ),
        );
      }
    } else {
      // Default placeholder
      return Container(
        width: imgWidth,
        height: imgHeight,
        decoration: BoxDecoration(
          color: const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.image, color: Color(0xFF9CA3AF)),
      );
    }
  }
}


Widget _buildLogo() {
  return Align(
    alignment: Alignment.centerLeft,
    child: Image.asset(
      'assets/images/image.png',
      height: 60,
      fit: BoxFit.contain,
      alignment: Alignment.centerLeft,
      errorBuilder: (context, error, stackTrace) {
        return const SizedBox(
          height: 60,
          child: Icon(Icons.image, color: Color(0xFFDC2626)),
        );
      },
    ),
  );
}

