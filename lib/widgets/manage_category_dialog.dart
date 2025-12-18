import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/category_service.dart';

class ManageCategoryDialog extends StatefulWidget {
  final VoidCallback? onCategoriesChanged;

  const ManageCategoryDialog({
    super.key,
    this.onCategoriesChanged,
  });

  @override
  State<ManageCategoryDialog> createState() => _ManageCategoryDialogState();
}

class _ManageCategoryDialogState extends State<ManageCategoryDialog> {
  final CategoryService _categoryService = CategoryService();
  final Map<String, TextEditingController> _editControllers = {};
  final TextEditingController _newCategoryController = TextEditingController();

  List<Category> _categories = [];
  String? _editingCategoryId;
  bool _isLoading = true;
  bool _isAddingNew = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
    });

    final categories =
        await _categoryService.getCategories(forceRefresh: forceRefresh);
    if (!mounted) return;

    // Deduplicate by name (case-insensitive) so the same category
    // is never shown multiple times in the list.
    final seenNames = <String>{};
    final uniqueCategories = <Category>[];
    for (final category in categories) {
      final key = category.name.trim().toLowerCase();
      if (seenNames.contains(key)) continue;
      seenNames.add(key);
      uniqueCategories.add(category);
    }

    setState(() {
      _categories = uniqueCategories;
      _isLoading = false;
    });
  }

  Future<void> _startEditing(Category category) async {
    setState(() {
      _editingCategoryId = category.id;
      _editControllers[category.id] ??=
          TextEditingController(text: category.name);
    });
  }

  Future<void> _saveEdit(Category category) async {
    final controller = _editControllers[category.id];
    if (controller == null) return;

    final newName = controller.text.trim();
    if (newName.isEmpty || newName == category.name) {
      setState(() {
        _editingCategoryId = null;
      });
      return;
    }

    final success =
        await _categoryService.updateCategory(category.id, newName);
    if (!mounted) return;

    if (success) {
      setState(() {
        final index = _categories.indexWhere((c) => c.id == category.id);
        if (index != -1) {
          _categories[index] = category.copyWith(name: newName);
        }
        _editingCategoryId = null;
      });
      widget.onCategoriesChanged?.call();
    }
  }

  Future<void> _deleteCategory(Category category) async {
    final success = await _categoryService.deleteCategory(category.id);
    if (!mounted) return;

    if (success) {
      setState(() {
        _categories.removeWhere((c) => c.id == category.id);
      });
      widget.onCategoriesChanged?.call();
    }
  }

  Future<void> _addCategory() async {
    final name = _newCategoryController.text.trim();
    if (name.isEmpty) return;

    // Prevent adding the same name multiple times in the UI (case-insensitive)
    final alreadyExists = _categories.any(
      (c) => c.name.toLowerCase() == name.toLowerCase(),
    );
    if (alreadyExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This category already exists.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final created = await _categoryService.addCategory(name);
    if (!mounted) return;

    if (created != null) {
      setState(() {
        _categories.add(created);
        _categories.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        _newCategoryController.clear();
        _isAddingNew = false;
      });
      widget.onCategoriesChanged?.call();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save category. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _editControllers.values) {
      controller.dispose();
    }
    _newCategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 80, vertical: 80),
      // Standard white dialog like the design screenshot
      backgroundColor: Colors.white,
      child: Center(
        child: ConstrainedBox(
          // Make the dialog narrower so it doesn't feel too wide
          constraints: const BoxConstraints(maxWidth: 640),
          child: Container(
            decoration: BoxDecoration(
              // Outer card is plain white, inner list card remains white as well
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      const Text(
                        'Manage Categories',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        splashRadius: 20,
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),

                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: _isLoading
                      ? const SizedBox(
                          height: 120,
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Inner white card with categories
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFE5E7EB),
                                ),
                              ),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  // Slightly smaller max height so the card
                                  // looks lighter like the design
                                  maxHeight: 260,
                                ),
                                child: SingleChildScrollView(
                                  child: Column(
                                    children: _categories.isEmpty
                                        ? [
                                            const Padding(
                                              padding: EdgeInsets.all(16),
                                              child: Text(
                                                'No categories found. Add a new category to get started.',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFF6B7280),
                                                ),
                                              ),
                                            ),
                                          ]
                                        : _categories
                                            .asMap()
                                            .entries
                                            .map((entry) {
                                              final index = entry.key;
                                              final category = entry.value;
                                              final isEditing =
                                                  _editingCategoryId ==
                                                      category.id;
                                              final controller =
                                                  _editControllers[
                                                          category.id] ??
                                                      TextEditingController(
                                                          text: category.name);
                                              _editControllers[category.id] ??=
                                                  controller;

                                              return Column(
                                                children: [
                                                  if (index != 0)
                                                    const Divider(
                                                      height: 1,
                                                      color: Color(0xFFE5E7EB),
                                                    ),
                                                  Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 16,
                                                      vertical: 12,
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Expanded(
                                                          child: isEditing
                                                              ? TextField(
                                                                  controller:
                                                                      controller,
                                                                  decoration:
                                                                      const InputDecoration(
                                                                    isDense:
                                                                        true,
                                                                    border:
                                                                        OutlineInputBorder(),
                                                                    contentPadding:
                                                                        EdgeInsets
                                                                            .symmetric(
                                                                      horizontal:
                                                                          12,
                                                                      vertical:
                                                                          10,
                                                                    ),
                                                                  ),
                                                                )
                                                              : Text(
                                                                  category
                                                                      .name,
                                                                  style:
                                                                      const TextStyle(
                                                                    fontSize:
                                                                        14,
                                                                    color: Color(
                                                                        0xFF111827),
                                                                  ),
                                                                ),
                                                        ),
                                                        const SizedBox(
                                                            width: 16),
                                                        TextButton(
                                                          onPressed: () {
                                                            if (isEditing) {
                                                              _saveEdit(
                                                                  category);
                                                            } else {
                                                              _startEditing(
                                                                  category);
                                                            }
                                                          },
                                                          child: Text(
                                                            isEditing
                                                                ? 'Save'
                                                                : 'Edit',
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 14,
                                                              color: Color(
                                                                  0xFF2563EB),
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 8),
                                                        TextButton(
                                                          onPressed: () {
                                                            _deleteCategory(
                                                                category);
                                                          },
                                                          child: const Text(
                                                            'Delete',
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              color: Color(
                                                                  0xFFDC2626),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              );
                                            }).toList(),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Inline add new category row
                            if (_isAddingNew)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _newCategoryController,
                                        autofocus: true,
                                        decoration: const InputDecoration(
                                          hintText: 'Enter category name',
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                          contentPadding:
                                              EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton(
                                      onPressed: _addCategory,
                                      child: const Text(
                                        'Save',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF2563EB),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _isAddingNew = false;
                                          _newCategoryController.clear();
                                        });
                                      },
                                      child: const Text(
                                        'Cancel',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // "Add new category" link
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isAddingNew = true;
                                  _newCategoryController.clear();
                                });
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add,
                                      size: 18, color: Color(0xFF2563EB)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Add new category',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),

                const Divider(height: 1, color: Color(0xFFE5E7EB)),

                // Footer with centered Close button, rounded like design
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Row(
                    // Close button aligned to the right like in the design image
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 10,
                          ),
                          foregroundColor: const Color(0xFF374151),
                          backgroundColor: const Color(0xFFF3F4F6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: const Text(
                          'Close',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


