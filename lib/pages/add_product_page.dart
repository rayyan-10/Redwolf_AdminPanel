import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:http/http.dart' as http;
import '../widgets/sidebar.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/supabase_service.dart';
import '../services/category_service.dart';
import '../widgets/manage_category_dialog.dart';

class AddProductPage extends StatefulWidget {
  final Product? product;
  
  const AddProductPage({super.key, this.product});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late List<Specification> _specifications;
  late List<String> _keyFeatures;
  late List<String> _selectedCategories;
  late List<TextEditingController> _specLabelControllers;
  late List<TextEditingController> _specValueControllers;
  late List<TextEditingController> _keyFeatureControllers;
  final CategoryService _categoryService = CategoryService();
  List<String> _availableCategories = [];
  PlatformFile? _glbFile;
  PlatformFile? _usdzFile;
  // Three images: [0] thumbnail, [1] second image, [2] third image
  final List<PlatformFile?> _productImages = [null, null, null];
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.product != null;
    
    // Initialize with default values first
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _specifications = [Specification(label: 'Dimension', value: '10×20×5 cm')];
    _keyFeatures = ['2 years warranty'];
    _selectedCategories = [];
    
    // Create controllers for dynamic specification and key feature fields (will be updated after loading product)
    _specLabelControllers = _specifications
        .map((s) => TextEditingController(text: s.label))
        .toList();
    _specValueControllers = _specifications
        .map((s) => TextEditingController(text: s.value))
        .toList();
    _keyFeatureControllers =
        _keyFeatures.map((k) => TextEditingController(text: k)).toList();

    // Load categories from database (with default seeding)
    _loadCategories();
    
    // If editing, fetch latest product data from database
    if (_isEditing && widget.product != null && widget.product!.id != null) {
      _loadProductForEditing(widget.product!.id!);
    } else if (_isEditing && widget.product != null) {
      // Fallback to passed product if no ID (shouldn't happen, but handle gracefully)
      _initializeWithProduct(widget.product!);
    }
  }
  
  // Fetch latest product data from database when editing
  Future<void> _loadProductForEditing(String productId) async {
    try {
      final productService = ProductService();
      final product = await productService.getProductById(productId);
      
      if (product != null && mounted) {
        _initializeWithProduct(product);
      } else if (widget.product != null && mounted) {
        // Fallback to passed product if fetch fails
        _initializeWithProduct(widget.product!);
      }
    } catch (e) {
      print('Error loading product for editing: $e');
      // Fallback to passed product if fetch fails
      if (widget.product != null && mounted) {
        _initializeWithProduct(widget.product!);
      }
    }
  }
  
  // Initialize form fields with product data
  void _initializeWithProduct(Product product) {
    setState(() {
      _titleController.text = product.name;
      _descriptionController.text = product.description ?? '';
      _selectedCategories = [product.category];
      _specifications = product.specifications?.map((s) => Specification(
        label: s['label'] ?? '',
        value: s['value'] ?? '',
      )).toList() ?? [Specification(label: 'Dimension', value: '10×20×5 cm')];
      _keyFeatures = product.keyFeatures ?? [];
      if (_keyFeatures.isEmpty) {
        _keyFeatures = ['2 years warranty'];
      }
      
      // Update controllers for dynamic fields
      _specLabelControllers = _specifications
          .map((s) => TextEditingController(text: s.label))
          .toList();
      _specValueControllers = _specifications
          .map((s) => TextEditingController(text: s.value))
          .toList();
      _keyFeatureControllers =
          _keyFeatures.map((k) => TextEditingController(text: k)).toList();
      
      // Load images and GLB file from URLs asynchronously
      _loadProductFiles(product);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (final c in _specLabelControllers) {
      c.dispose();
    }
    for (final c in _specValueControllers) {
      c.dispose();
    }
    for (final c in _keyFeatureControllers) {
      c.dispose();
    }
    super.dispose();
  }
  
  // Load images and GLB file from URLs when editing
  Future<void> _loadProductFiles(Product product) async {
    // Load thumbnail image (first image)
    if (product.imageUrl.isNotEmpty && 
        (product.imageUrl.startsWith('http://') || product.imageUrl.startsWith('https://'))) {
      try {
        final response = await http.get(Uri.parse(product.imageUrl));
        if (response.statusCode == 200) {
          setState(() {
            _productImages[0] = PlatformFile(
              name: 'thumbnail.png',
              bytes: response.bodyBytes,
              size: response.bodyBytes.length,
            );
          });
        }
      } catch (e) {
        print('Error loading thumbnail image: $e');
      }
    }
    
    // Load second image if available
    if (product.secondImageUrl != null && 
        product.secondImageUrl!.isNotEmpty &&
        (product.secondImageUrl!.startsWith('http://') || product.secondImageUrl!.startsWith('https://'))) {
      try {
        final response = await http.get(Uri.parse(product.secondImageUrl!));
        if (response.statusCode == 200) {
          setState(() {
            _productImages[1] = PlatformFile(
              name: 'image2.png',
              bytes: response.bodyBytes,
              size: response.bodyBytes.length,
            );
          });
        }
      } catch (e) {
        print('Error loading second image: $e');
      }
    }

    // Load third image if available
    if (product.thirdImageUrl != null &&
        product.thirdImageUrl!.isNotEmpty &&
        (product.thirdImageUrl!.startsWith('http://') ||
            product.thirdImageUrl!.startsWith('https://'))) {
      try {
        final response = await http.get(Uri.parse(product.thirdImageUrl!));
        if (response.statusCode == 200) {
          setState(() {
            _productImages[2] = PlatformFile(
              name: 'image3.png',
              bytes: response.bodyBytes,
              size: response.bodyBytes.length,
            );
          });
        }
      } catch (e) {
        print('Error loading third image: $e');
      }
    }
    
    // Load GLB file if available
    if (product.glbFileUrl != null && 
        product.glbFileUrl!.isNotEmpty &&
        (product.glbFileUrl!.startsWith('http://') || product.glbFileUrl!.startsWith('https://'))) {
      try {
        final response = await http.get(Uri.parse(product.glbFileUrl!));
        if (response.statusCode == 200) {
          setState(() {
            _glbFile = PlatformFile(
              name: 'model.glb',
              bytes: response.bodyBytes,
              size: response.bodyBytes.length,
            );
          });
        }
      } catch (e) {
        print('Error loading GLB file: $e');
      }
    }
    
    // Load USDZ file if available
    if (product.usdzFileUrl != null && 
        product.usdzFileUrl!.isNotEmpty &&
        (product.usdzFileUrl!.startsWith('http://') || product.usdzFileUrl!.startsWith('https://'))) {
      try {
        final response = await http.get(Uri.parse(product.usdzFileUrl!));
        if (response.statusCode == 200) {
          setState(() {
            _usdzFile = PlatformFile(
              name: 'model.usdz',
              bytes: response.bodyBytes,
              size: response.bodyBytes.length,
            );
          });
        }
      } catch (e) {
        print('Error loading USDZ file: $e');
      }
    }
  }

  Future<void> _loadCategories({bool forceRefresh = false}) async {
    try {
      final categories =
          await _categoryService.getCategories(forceRefresh: forceRefresh);
      if (!mounted) return;

      final names = categories.map((c) => c.name).toList();

      setState(() {
        _availableCategories = names;

        // Ensure the selected category is present in the available list
        if (_selectedCategories.isNotEmpty &&
            !_availableCategories.contains(_selectedCategories.first)) {
          _availableCategories.insert(0, _selectedCategories.first);
        }
      });
    } catch (e) {
      // If loading categories fails, keep any existing in-memory list
      debugPrint('Error loading categories: $e');
    }
  }

  Future<void> _openManageCategoryDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return ManageCategoryDialog(
          onCategoriesChanged: () async {
            await _loadCategories(forceRefresh: true);
          },
        );
      },
    );

    // Reload categories after dialog is closed to ensure latest data
    await _loadCategories(forceRefresh: true);
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
              title: _buildHeader(isMobile: true),
            ),
            body: _buildContent(isMobile),
          );
        }
        
        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          body: Row(
            children: [
              const Sidebar(currentRoute: '/products'),
              Expanded(
                child: Column(
                  children: [
                    _buildHeader(isMobile: false),
                    Expanded(
                      child: _buildContent(isMobile),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader({required bool isMobile}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
          Text(
            _isEditing ? 'Edit Product' : 'Add New Product',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const Spacer(),
          if (!isMobile) ...[
            _buildHeaderButton('Cancel', isSecondary: true),
            const SizedBox(width: 12),
            _buildHeaderButton('Save Draft', isSecondary: true, isRed: true),
            const SizedBox(width: 12),
            _buildHeaderButton('Publish', isSecondary: false),
          ],
        ],
      ),
    );
  }

  Future<void> _saveProduct(String status) async {
    // Validate required fields
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a product title'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Require a product description
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a product description'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Require all three product images (thumbnail + image 2 + image 3)
    final hasFirstImage = _productImages[0] != null ||
        (_isEditing &&
            widget.product != null &&
            (widget.product!.imageUrl.isNotEmpty));
    final hasSecondImage = _productImages[1] != null ||
        (_isEditing &&
            widget.product != null &&
            (widget.product!.secondImageUrl?.isNotEmpty ?? false));
    final hasThirdImage = _productImages[2] != null ||
        (_isEditing &&
            widget.product != null &&
            (widget.product!.thirdImageUrl?.isNotEmpty ?? false));

    if (!hasFirstImage || !hasSecondImage || !hasThirdImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please upload all 3 product images before saving the product'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Require GLB file
    final hasGlbFile = _glbFile != null ||
        (_isEditing &&
            widget.product != null &&
            (widget.product!.glbFileUrl?.isNotEmpty ?? false));

    if (!hasGlbFile) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload the 3D GLB file before saving'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Require at least one complete specification
    final hasValidSpecification = _specifications.any(
      (spec) =>
          spec.label.trim().isNotEmpty && spec.value.trim().isNotEmpty,
    );
    if (!hasValidSpecification) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one specification'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Require at least one key feature
    final hasValidKeyFeature =
        _keyFeatures.any((feature) => feature.trim().isNotEmpty);
    if (!hasValidKeyFeature) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one key feature'),
          backgroundColor: Colors.red,
        ),
      );
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
      final supabase = SupabaseService();
      final productService = ProductService();
      const bucketName = 'products'; // Supabase storage bucket name

      String? thumbnailImageUrl;
      String? secondImageUrl;
      String? glbFileUrl;
      String? usdzFileUrl;
      String? thirdImageUrl;

      // If editing, start with existing URLs
      if (_isEditing && widget.product != null) {
        thumbnailImageUrl = widget.product!.imageUrl;
        secondImageUrl = widget.product!.secondImageUrl;
        glbFileUrl = widget.product!.glbFileUrl;
        usdzFileUrl = widget.product!.usdzFileUrl;
        thirdImageUrl = widget.product!.thirdImageUrl;
      }

      // Upload thumbnail image (first image) if new image is selected
      if (_productImages[0] != null && _productImages[0]!.bytes != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'thumbnail_${timestamp}_${_productImages[0]!.name}';
        final uploadedUrl = await supabase.uploadImage(
          fileBytes: Uint8List.fromList(_productImages[0]!.bytes!),
          fileName: fileName,
          bucketName: bucketName,
        );
        if (uploadedUrl != null) {
          thumbnailImageUrl = uploadedUrl;
        }
      }

      // Upload second image if new image is selected
      if (_productImages[1] != null && _productImages[1]!.bytes != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'image2_${timestamp}_${_productImages[1]!.name}';
        final uploadedUrl = await supabase.uploadImage(
          fileBytes: Uint8List.fromList(_productImages[1]!.bytes!),
          fileName: fileName,
          bucketName: bucketName,
        );
        if (uploadedUrl != null) {
          secondImageUrl = uploadedUrl;
        }
      }

      // Upload third image if new image is selected
      if (_productImages[2] != null && _productImages[2]!.bytes != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'image3_${timestamp}_${_productImages[2]!.name}';
        final uploadedUrl = await supabase.uploadImage(
          fileBytes: Uint8List.fromList(_productImages[2]!.bytes!),
          fileName: fileName,
          bucketName: bucketName,
        );
        if (uploadedUrl != null) {
          thirdImageUrl = uploadedUrl;
        }
      }

      // Upload GLB file if new file is selected
      if (_glbFile != null && _glbFile!.bytes != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'model_${timestamp}_${_glbFile!.name}';
        final uploadedUrl = await supabase.uploadGlbFile(
          fileBytes: Uint8List.fromList(_glbFile!.bytes!),
          fileName: fileName,
          bucketName: bucketName,
        );
        if (uploadedUrl != null) {
          glbFileUrl = uploadedUrl;
        }
      }

      // Upload USDZ file if new file is selected (optional, for Apple devices)
      if (_usdzFile != null && _usdzFile!.bytes != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'model_${timestamp}_${_usdzFile!.name}';
        final uploadedUrl = await supabase.uploadUsdzFile(
          fileBytes: Uint8List.fromList(_usdzFile!.bytes!),
          fileName: fileName,
          bucketName: bucketName,
        );
        if (uploadedUrl != null) {
          usdzFileUrl = uploadedUrl;
        }
      }

      // Use default placeholder if no thumbnail available
      if (thumbnailImageUrl == null || thumbnailImageUrl.isEmpty) {
        thumbnailImageUrl = 'assets/images/image_1.png';
      }

      // Create specifications map
      final specifications = _specifications
          .where((spec) => spec.label.isNotEmpty && spec.value.isNotEmpty)
          .map((spec) => {'label': spec.label, 'value': spec.value})
          .toList();

      // Create key features list (filter empty ones)
      final keyFeatures = _keyFeatures.where((feature) => feature.isNotEmpty).toList();

      // Create product
      final product = Product(
        id: _isEditing && widget.product != null ? widget.product!.id : null,
        name: _titleController.text.trim(),
        category: _selectedCategories.first,
        status: status,
        imageUrl: thumbnailImageUrl ?? '',
        secondImageUrl: secondImageUrl,
        thirdImageUrl: thirdImageUrl,
        glbFileUrl: glbFileUrl,
        usdzFileUrl: usdzFileUrl,
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        specifications: specifications.isEmpty ? null : specifications,
        keyFeatures: keyFeatures.isEmpty ? null : keyFeatures,
      );

      // Add or update product in database
      bool success = false;
      if (_isEditing && widget.product != null && widget.product!.id != null) {
        success = await productService.updateProduct(widget.product!.id!, product);
      } else {
        final productId = await productService.addProduct(product);
        success = productId != null;
      }

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (success) {
        if (mounted) {
          // Invalidate cache to ensure fresh data
          productService.invalidateCache();
          // Force refresh cache before navigating
          await productService.getProducts(forceRefresh: true);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Product ${status.toLowerCase()} successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Navigate back using pop to trigger the .then() callback in products page
          Navigator.of(context).pop(true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error saving product. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildHeaderButton(String text, {required bool isSecondary, bool isRed = false}) {
    return SizedBox(
      height: 40,
      child: ElevatedButton(
        onPressed: () {
          if (text == 'Cancel') {
            Navigator.of(context).pop();
          } else if (text == 'Save Draft') {
            _saveProduct('Draft');
          } else if (text == 'Publish') {
            _saveProduct('Published');
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSecondary
              ? (isRed ? Colors.white : Colors.white)
              : const Color(0xFFDC2626),
          foregroundColor: isSecondary
              ? (isRed ? const Color(0xFFDC2626) : const Color(0xFF374151))
              : Colors.white,
          side: isSecondary
              ? BorderSide(
                  color: isRed ? const Color(0xFFDC2626) : const Color(0xFFE5E7EB),
                )
              : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isMobile) {
    if (isMobile) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Information
            _buildSectionCard(
              'Product Information',
              [
                _buildTextField(
                  controller: _titleController,
                  label: 'Product Title',
                  placeholder: 'Enter product name',
                ),
                const SizedBox(height: 24),
                _buildTextArea(
                  controller: _descriptionController,
                  label: 'Product Description',
                  placeholder: 'Enter product description',
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Media
            _buildSectionCard(
              'Media',
              [
                const Text(
                  'Product Images (Max 2, first is thumbnail)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 12),
                _buildImageUploadSection(),
                const SizedBox(height: 24),
                const Text(
                  '3D Model for AR(.glb only)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 12),
                _buildGlbUploadBox(),
                const SizedBox(height: 24),
                const Text(
                  '3D Model for AR - Apple Devices (.usdz only)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 12),
                _buildUsdzUploadBox(),
              ],
            ),
            const SizedBox(height: 24),
            // Categories
            _buildSectionCard(
              'Categories',
              [
                const SizedBox(height: 16),
                ..._availableCategories.map((category) => _buildCheckbox(category)),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _openManageCategoryDialog,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 18, color: Color(0xFF2563EB)),
                      SizedBox(width: 4),
                      Text(
                        'Add new category',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF2563EB),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              headerAction: TextButton(
                onPressed: _openManageCategoryDialog,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Manage category',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF2563EB),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Specifications
            _buildSectionCard(
              'Specifications',
              [
                ..._specifications.asMap().entries.map((entry) {
                  final index = entry.key;
                  final spec = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(bottom: index < _specifications.length - 1 ? 12 : 0),
                    child: _buildSpecificationRow(spec, index),
                  );
                }),
                const SizedBox(height: 12),
                _buildAddButton(
                  'Add Specification',
                  isSecondary: true,
                  onPressed: () {
                    setState(() {
                      _specifications.add(Specification(label: '', value: ''));
                      _specLabelControllers.add(TextEditingController());
                      _specValueControllers.add(TextEditingController());
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Key Features
            _buildSectionCard(
              'Key Features',
              [
                ..._keyFeatures.asMap().entries.map((entry) {
                  final index = entry.key;
                  return Padding(
                    padding: EdgeInsets.only(bottom: index < _keyFeatures.length - 1 ? 12 : 0),
                    child: _buildKeyFeatureRow(index),
                  );
                }),
                const SizedBox(height: 12),
                _buildAddButton(
                  'Add Key Feature',
                  isSecondary: true,
                  isRed: true,
                  onPressed: () {
                    setState(() {
                      _keyFeatures.add('');
                      _keyFeatureControllers.add(TextEditingController());
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildHeaderButton('Cancel', isSecondary: true),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildHeaderButton('Save Draft', isSecondary: true, isRed: true),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildHeaderButton('Publish', isSecondary: false),
                ),
              ],
            ),
            const SizedBox(height: 100),
          ],
        ),
      );
    }

    // Desktop layout - Two columns
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Information
                _buildSectionCard(
                  'Product Information',
                  [
                    _buildTextField(
                      controller: _titleController,
                      label: 'Product Title',
                      placeholder: 'Enter product name',
                    ),
                    const SizedBox(height: 24),
                    _buildTextArea(
                      controller: _descriptionController,
                      label: 'Product Description',
                      placeholder: 'Enter product description',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Media
                _buildSectionCard(
                  'Media',
                  [
                    const Text(
                      'Product Images (Max 2, first is thumbnail)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildImageUploadSection(),
                    const SizedBox(height: 24),
                    const Text(
                      '3D Model for AR(.glb only)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildGlbUploadBox(),
                    const SizedBox(height: 24),
                    const Text(
                      '3D Model for AR - Apple Devices (.usdz only)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildUsdzUploadBox(),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Right Column
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Categories
                _buildSectionCard(
                  'Categories',
                  [
                    const SizedBox(height: 16),
                    ..._availableCategories.map((category) => _buildCheckbox(category)),
                    const SizedBox(height: 12),
                    TextButton(
                  onPressed: _openManageCategoryDialog,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 18, color: Color(0xFF2563EB)),
                          SizedBox(width: 4),
                          Text(
                            'Add new category',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF2563EB),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  headerAction: TextButton(
                onPressed: _openManageCategoryDialog,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Manage category',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF2563EB),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Specifications
                _buildSectionCard(
                  'Specifications',
                  [
                    ..._specifications.asMap().entries.map((entry) {
                      final index = entry.key;
                      final spec = entry.value;
                      return Padding(
                        padding: EdgeInsets.only(bottom: index < _specifications.length - 1 ? 12 : 0),
                        child: _buildSpecificationRow(spec, index),
                      );
                    }),
                    const SizedBox(height: 12),
                    _buildAddButton(
                      'Add Specification',
                      isSecondary: true,
                      onPressed: () {
                        setState(() {
                          _specifications.add(Specification(label: '', value: ''));
                      _specLabelControllers.add(TextEditingController());
                      _specValueControllers.add(TextEditingController());
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Key Features
                _buildSectionCard(
                  'Key Features',
                  [
                    ..._keyFeatures.asMap().entries.map((entry) {
                      final index = entry.key;
                      return Padding(
                        padding: EdgeInsets.only(bottom: index < _keyFeatures.length - 1 ? 12 : 0),
                        child: _buildKeyFeatureRow(index),
                      );
                    }),
                    const SizedBox(height: 12),
                    _buildAddButton(
                      'Add Key Feature',
                      isSecondary: true,
                      isRed: true,
                      onPressed: () {
                        setState(() {
                          _keyFeatures.add('');
                      _keyFeatureControllers.add(TextEditingController());
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children, {Widget? headerAction}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              if (headerAction != null) headerAction,
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String placeholder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: placeholder,
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
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFDC2626), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildTextArea({
    required TextEditingController controller,
    required String label,
    required String placeholder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: placeholder,
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
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFDC2626), width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadBox({
    required IconData icon,
    required String text,
    String? subtitle,
    required double height,
  }) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFD1D5DB),
          style: BorderStyle.solid,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: const Color(0xFF9CA3AF)),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          SizedBox(
            width: 150,
            child: _buildImageUploadBox(i),
          ),
        ],
      ],
    );
  }

  Widget _buildImageUploadBox(int index) {
    final imageFile = _productImages[index];
    
    return Container(
      width: 150,
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFD1D5DB),
          style: BorderStyle.solid,
          width: 2,
        ),
      ),
      child: imageFile == null
          ? InkWell(
              onTap: () => _pickImage(index),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.upload_file, size: 32, color: const Color(0xFF9CA3AF)),
                  const SizedBox(height: 8),
                  const Text(
                    'Upload Image',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 150,
                    height: 120,
                    child: imageFile.bytes != null
                        ? Image.memory(
                            imageFile.bytes!,
                            width: 150,
                            height: 120,
                            fit: BoxFit.contain,
                          )
                        : _getImageFromPath(imageFile),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                      padding: const EdgeInsets.all(4),
                      minimumSize: const Size(24, 24),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () {
                      setState(() {
                        _productImages[index] = null;
                      });
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _getImageFromPath(PlatformFile file) {
    try {
      if (file.path != null && file.path!.isNotEmpty) {
        return Image.asset(
          file.path!,
          width: 150,
          height: 120,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return _buildImageErrorPlaceholder();
          },
        );
      }
    } catch (e) {
      // On web, accessing path throws
    }
    return _buildImageErrorPlaceholder();
  }

  Widget _buildImageErrorPlaceholder() {
    return Container(
      width: 150,
      height: 120,
      color: const Color(0xFFE5E7EB),
      child: const Icon(Icons.image, color: Color(0xFF9CA3AF)),
    );
  }

  Future<void> _pickImage(int index) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null) {
        final file = result.files.single;
        bool hasValidFile = false;
        if (file.bytes != null) {
          hasValidFile = true;
        } else {
          try {
            if (file.path != null && file.path!.isNotEmpty) {
              hasValidFile = true;
            }
          } catch (e) {
            // On web, accessing path throws, so we ignore it
          }
        }
        
        if (hasValidFile) {
          setState(() {
            _productImages[index] = file;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildGlbUploadBox() {
    return Container(
      height: 400,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFD1D5DB),
          style: BorderStyle.solid,
          width: 2,
        ),
      ),
      child: _getGlbFileUrl() == null
          ? InkWell(
              onTap: _pickGlbFile,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.view_in_ar, size: 32, color: const Color(0xFF9CA3AF)),
                  const SizedBox(height: 8),
                  const Text(
                    'Upload Model',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'only .glb files',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: 400,
                    width: double.infinity,
                    child: _getGlbFileUrl() != null
                        ? ModelViewer(
                            src: _getGlbFileUrl()!,
                            alt: '3D Model',
                            ar: true,
                            autoRotate: true,
                            cameraControls: true,
                            backgroundColor: const Color(0xFFF9FAFB),
                            loading: Loading.auto,
                          )
                        : const Center(
                            child: Text(
                              'GLB file selected',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                    ),
                    onPressed: () {
                      setState(() {
                        _glbFile = null;
                      });
                    },
                  ),
                ),
              ],
            ),
    );
  }

  String? _getGlbFileUrl() {
    if (_glbFile == null) return null;
    
    // On web, path is unavailable, so check bytes first
    if (_glbFile!.bytes != null) {
      // For web, convert bytes to data URL with correct MIME type
      final base64 = base64Encode(_glbFile!.bytes!);
      return 'data:model/gltf-binary;base64,$base64';
    }
    // For desktop/mobile, try to use path (but don't access it if it might throw)
    try {
      if (_glbFile!.path != null && _glbFile!.path!.isNotEmpty) {
        return _glbFile!.path;
      }
    } catch (e) {
      // On web, accessing path throws, so we ignore it
    }
    return null;
  }

  Future<void> _pickGlbFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['glb'],
        withData: true,
      );

      if (result != null) {
        final file = result.files.single;
        // On web, path is unavailable and accessing it throws
        // So we check bytes first (which works on all platforms)
        bool hasValidFile = false;
        if (file.bytes != null) {
          hasValidFile = true;
        } else {
          // Only check path on non-web platforms (wrapped in try-catch)
          try {
            if (file.path != null && file.path!.isNotEmpty) {
              hasValidFile = true;
            }
          } catch (e) {
            // On web, accessing path throws, so we ignore it
            // File should have bytes instead
          }
        }
        
        if (hasValidFile) {
          setState(() {
            _glbFile = file;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildCheckbox(String category) {
    final isSelected = _selectedCategories.contains(category);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Checkbox(
            value: isSelected,
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _selectedCategories.add(category);
                } else {
                  _selectedCategories.remove(category);
                }
              });
            },
            activeColor: const Color(0xFFDC2626),
          ),
          Text(
            category,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecificationRow(Specification spec, int index) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _specLabelControllers[index],
            decoration: InputDecoration(
              hintText: 'e.g. Dimension',
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              setState(() {
                _specifications[index].label = value;
              });
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _specValueControllers[index],
            decoration: InputDecoration(
              hintText: 'Value',
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              setState(() {
                _specifications[index].value = value;
              });
            },
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
          onPressed: () {
            setState(() {
              _specifications.removeAt(index);
              _specLabelControllers.removeAt(index);
              _specValueControllers.removeAt(index);
            });
          },
        ),
      ],
    );
  }

  Widget _buildKeyFeatureRow(int index) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _keyFeatureControllers[index],
            decoration: InputDecoration(
              hintText: index == 0 ? null : 'E.g. 4K Display',
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              setState(() {
                _keyFeatures[index] = value;
              });
            },
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
          onPressed: () {
            setState(() {
              _keyFeatures.removeAt(index);
              _keyFeatureControllers.removeAt(index);
            });
          },
        ),
      ],
    );
  }

  Widget _buildAddButton(String text, {required bool isSecondary, bool isRed = false, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: isRed ? const Color(0xFFDC2626) : const Color(0xFF374151),
          side: BorderSide(
            color: isRed ? const Color(0xFFDC2626) : const Color(0xFFE5E7EB),
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add,
              size: 20,
              color: isRed ? const Color(0xFFDC2626) : const Color(0xFF374151),
            ),
            const SizedBox(width: 8),
            Text(
              text.replaceAll('+ ', '').replaceAll('+', ''),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isRed ? const Color(0xFFDC2626) : const Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsdzUploadBox() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFD1D5DB),
          style: BorderStyle.solid,
          width: 2,
        ),
      ),
      child: _getUsdzFileUrl() == null
          ? InkWell(
              onTap: _pickUsdzFile,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.view_in_ar, size: 32, color: const Color(0xFF9CA3AF)),
                  const SizedBox(height: 8),
                  const Text(
                    'Upload USDZ Model (Optional)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'only .usdz files (for Apple devices)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, size: 48, color: Colors.green),
                        SizedBox(height: 8),
                        Text(
                          'USDZ file selected',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                    ),
                    onPressed: () {
                      setState(() {
                        _usdzFile = null;
                      });
                    },
                  ),
                ),
              ],
            ),
    );
  }

  String? _getUsdzFileUrl() {
    if (_usdzFile == null) return null;
    
    // On web, path is unavailable, so check bytes first
    if (_usdzFile!.bytes != null) {
      // For web, convert bytes to data URL with correct MIME type
      final base64 = base64Encode(_usdzFile!.bytes!);
      return 'data:model/vnd.usdz+zip;base64,$base64';
    }
    // For desktop/mobile, try to use path (but don't access it if it might throw)
    try {
      if (_usdzFile!.path != null && _usdzFile!.path!.isNotEmpty) {
        return _usdzFile!.path;
      }
    } catch (e) {
      // On web, accessing path throws, so we ignore it
    }
    return null;
  }

  Future<void> _pickUsdzFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['usdz'],
        withData: true,
      );

      if (result != null) {
        final file = result.files.single;
        // On web, path is unavailable and accessing it throws
        // So we check bytes first (which works on all platforms)
        bool hasValidFile = false;
        if (file.bytes != null) {
          hasValidFile = true;
        } else {
          try {
            if (file.path != null && file.path!.isNotEmpty) {
              hasValidFile = true;
            }
          } catch (e) {
            // On web, accessing path throws, so we ignore it
          }
        }
        
        if (hasValidFile) {
          setState(() {
            _usdzFile = file;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking USDZ file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class Specification {
  String label;
  String value;

  Specification({required this.label, required this.value});
}

