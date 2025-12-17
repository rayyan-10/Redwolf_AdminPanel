class Product {
  final String? id; // Database ID
  final String name;
  final String category;
  final String status;
  final String imageUrl; // Thumbnail image URL
  final String? secondImageUrl; // Second image URL
  final String? glbFileUrl; // GLB file URL
  final String? description;
  final List<Map<String, String>>? specifications;
  final List<String>? keyFeatures;
  final List<int>? imageBytes; // Store image bytes for uploaded images (local only)
  final String? imageDataUrl; // Store data URL for web (local only)
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Product({
    this.id,
    required this.name,
    required this.category,
    required this.status,
    required this.imageUrl,
    this.secondImageUrl,
    this.glbFileUrl,
    this.description,
    this.specifications,
    this.keyFeatures,
    this.imageBytes,
    this.imageDataUrl,
    this.createdAt,
    this.updatedAt,
  });

  // Convert from JSON (database)
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String?,
      name: json['name'] as String,
      category: json['category'] as String,
      status: json['status'] as String,
      imageUrl: json['image_url'] as String? ?? '',
      secondImageUrl: json['second_image_url'] as String?,
      glbFileUrl: json['glb_file_url'] as String?,
      description: json['description'] as String?,
      specifications: json['specifications'] != null
          ? List<Map<String, String>>.from(
              (json['specifications'] as List).map((item) => Map<String, String>.from(item)))
          : null,
      keyFeatures: json['key_features'] != null
          ? List<String>.from(json['key_features'] as List)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  // Convert to JSON (for database)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'category': category,
      'status': status,
      'image_url': imageUrl,
      if (secondImageUrl != null) 'second_image_url': secondImageUrl,
      if (glbFileUrl != null) 'glb_file_url': glbFileUrl,
      if (description != null) 'description': description,
      if (specifications != null) 'specifications': specifications,
      if (keyFeatures != null) 'key_features': keyFeatures,
    };
  }

  // Copy with method for updates
  Product copyWith({
    String? id,
    String? name,
    String? category,
    String? status,
    String? imageUrl,
    String? secondImageUrl,
    String? glbFileUrl,
    String? description,
    List<Map<String, String>>? specifications,
    List<String>? keyFeatures,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      secondImageUrl: secondImageUrl ?? this.secondImageUrl,
      glbFileUrl: glbFileUrl ?? this.glbFileUrl,
      description: description ?? this.description,
      specifications: specifications ?? this.specifications,
      keyFeatures: keyFeatures ?? this.keyFeatures,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
