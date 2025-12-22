# Admin Panel Guide

Complete guide to all features and functionality of the REDWOLF MEDIA Admin Panel.

## 📑 Table of Contents

- [Pages Overview](#pages-overview)
- [Login Page](#login-page)
- [Dashboard Page](#dashboard-page)
- [Products Page](#products-page)
- [Add/Edit Product Page](#addedit-product-page)
- [Category Management](#category-management)
- [Services & Functions](#services--functions)
- [Models & Data Structures](#models--data-structures)

---

## 📄 Pages Overview

The admin panel consists of four main pages:

1. **Login Page** (`/login`) - Authentication entry point
2. **Dashboard Page** (`/dashboard`) - Overview with metrics and recent activity
3. **Products Page** (`/products`) - Product listing and management
4. **Add Product Page** (`/products/add`) - Create or edit products

---

## 🔐 Login Page

**File**: `lib/pages/login_page.dart`  
**Route**: `/login`

### Features

- Simple login form with email and password fields
- Password visibility toggle
- Responsive design for all screen sizes
- Navigation to dashboard on successful login

### Functions

#### `_LoginPageState`
- **`build()`**: Builds the login UI with form fields
- **`dispose()`**: Cleans up text controllers

### UI Components

- **Email Field**: Text input for user email
- **Password Field**: Text input with visibility toggle
- **Login Button**: Navigates to dashboard
- **Support Link**: "Get support" text button
- **Footer**: "Built by Ruditech" footer

### Navigation Flow

```
Login → Dashboard (on successful login)
```

---

## 📊 Dashboard Page

**File**: `lib/pages/dashboard_page.dart`  
**Route**: `/dashboard`

### Features

- **Real-time Product Count**: Displays total number of products from database
- **Metric Cards**: Three metric cards showing:
  - Product Count (real-time from DB)
  - AR Views (static placeholder)
  - AR Views with Insights (static placeholder)
- **Recent Activity Feed**: Shows last 3 products with:
  - Product name
  - Category
  - Status badge (Published/Draft)
  - Time ago (e.g., "2 hr ago", "3 weeks ago")

### Real-time Updates

Uses Supabase real-time streams to automatically update:
- Product count when products are added/deleted
- Recent activity when products are created/updated

### Functions

#### `DashboardPage`
- **`build()`**: Main build method with responsive layout
- **`_buildContent()`**: Builds main content area with StreamBuilder
- **`_buildMetricCards()`**: Creates metric card widgets
- **`_buildMetricCard()`**: Builds individual metric card
- **`_buildActivityItem()`**: Builds recent activity item

#### Helper Functions
- **`_formatTimeAgo()`**: Formats DateTime to human-readable time ago string

### Data Flow

```
Supabase Stream → StreamBuilder → Product List → UI Update
```

### UI Components

- **Sidebar**: Navigation menu (from `Sidebar` widget)
- **Metric Cards**: White cards with icons, values, and trends
- **Recent Activity Section**: White container with activity list
- **Footer**: Application footer (from `Footer` widget)

### Responsive Behavior

- **Mobile**: Stacked layout, drawer navigation
- **Tablet**: Grid layout for metric cards
- **Desktop**: Horizontal row layout for metric cards

---

## 📦 Products Page

**File**: `lib/pages/products_page.dart`  
**Route**: `/products`

### Features

- **Product Listing**: Displays all products in a table/card format
- **Search Functionality**: Search by product name, category, or description
- **Filter Dropdown**: Filter by "All Products", "Published", or "Draft"
- **Product Actions**: 
  - View (placeholder)
  - Duplicate
  - Edit
  - Delete
- **Manage Categories**: Opens category management dialog
- **Add Product**: Navigate to add product page

### Functions

#### `_ProductsPageState`

##### Initialization
- **`initState()`**: Sets up search listener and loads products
- **`didChangeDependencies()`**: Refreshes products when page becomes visible
- **`dispose()`**: Cleans up controllers

##### Product Loading
- **`_loadProductsInstantly()`**: Loads cached products immediately (no delay)
- **`_loadProductsSilently()`**: Refreshes products in background
- **`_refreshProducts()`**: Force refresh from database
- **`_loadProducts()`**: Main loading method with optional force refresh

##### Filtering & Search
- **`_getFilteredAndSearchedProducts()`**: Applies both filter and search query
- **`_onSearchChanged()`**: Triggered when search text changes

##### Product Operations
- **`_duplicateProduct()`**: Creates a copy of a product with "(Copy)" suffix
- **`_showDeleteDialog()`**: Shows confirmation dialog before deletion
- **`_deleteProduct()`**: Deletes product from database

##### UI Building
- **`build()`**: Main build with responsive layout
- **`_buildContent()`**: Builds main content area
- **`_buildHeader()`**: Builds header with search, filters, and buttons
- **`_buildFilterDropdown()`**: Creates filter dropdown widget
- **`_buildButton()`**: Creates action buttons (Add product, Manage Category)
- **`_buildProductsTable()`**: Builds product table (desktop/tablet)
- **`_buildMobileProductCard()`**: Builds product card (mobile)
- **`_buildDataColumnLabel()`**: Creates table column headers
- **`_buildDataRow()`**: Creates table row for each product
- **`_buildStatusChip()`**: Creates status badge widget
- **`_buildActionIcons()`**: Creates action icon buttons
- **`_buildProductImage()`**: Displays product thumbnail image

### Product Display

#### Desktop/Tablet View
- **DataTable** with columns:
  - Product Info (image + name)
  - Category
  - Status (badge)
  - Actions (view, duplicate, edit, delete icons)

#### Mobile View
- **Card Layout** with:
  - Product image
  - Product name and category
  - Status badge
  - Action icons at bottom

### Search & Filter Logic

1. **Filter Applied First**: Filters by status (All/Published/Draft)
2. **Search Applied Second**: Searches within filtered results
3. **Case-Insensitive**: All searches are case-insensitive

### Cache Management

- Products cached for 5 minutes
- Instant display from cache on page load
- Background refresh without blocking UI
- Force refresh after add/edit/delete operations

---

## ➕ Add/Edit Product Page

**File**: `lib/pages/add_product_page.dart`  
**Route**: `/products/add`

### Features

- **Create New Product**: Add new products with all details
- **Edit Existing Product**: Edit products by passing product object
- **Image Uploads**: Upload up to 3 images per product
- **GLB File Upload**: Upload 3D model files for AR visualization
- **Dynamic Specifications**: Add/remove specification key-value pairs
- **Dynamic Key Features**: Add/remove key feature items
- **Category Selection**: Select from available categories
- **Status Management**: Save as Draft or Publish

### Functions

#### `_AddProductPageState`

##### Initialization
- **`initState()`**: 
  - Initializes form controllers
  - Loads product data if editing
  - Fetches latest product from DB if editing
  - Loads categories from database
- **`dispose()`**: Disposes all text controllers

##### Product Loading (Edit Mode)
- **`_loadProductForEditing()`**: Fetches latest product data from database
- **`_initializeWithProduct()`**: Initializes form fields with product data
- **`_loadProductFiles()`**: Loads images and GLB file from URLs

##### Category Management
- **`_loadCategories()`**: Fetches categories from CategoryService
- Opens ManageCategoryDialog for category management

##### File Operations
- **`_pickImage()`**: Opens file picker for image selection
- **`_pickGlbFile()`**: Opens file picker for GLB file selection
- **`_removeImage()`**: Removes selected image
- **`_removeGlbFile()`**: Removes selected GLB file

##### Form Building
- **`build()`**: Main build method
- **`_buildHeader()`**: Header with back button and action buttons
- **`_buildImageUploadSection()`**: Image upload UI (3 image slots)
- **`_buildGlbUploadSection()`**: GLB file upload UI with preview
- **`_buildSpecificationRow()`**: Builds specification input row
- **`_buildKeyFeatureRow()`**: Builds key feature input row
- **`_addSpecification()`**: Adds new specification row
- **`_removeSpecification()`**: Removes specification row
- **`_addKeyFeature()`**: Adds new key feature row
- **`_removeKeyFeature()`**: Removes key feature row

##### Product Saving
- **`_saveProduct()`**: Main save method
  - Validates all required fields
  - Uploads images to Supabase Storage
  - Uploads GLB file to Supabase Storage
  - Creates/updates product in database
  - Invalidates cache
  - Navigates back to products page

### Form Fields

1. **Product Title**: Required text field
2. **Description**: Optional text area
3. **Category**: Dropdown selection from available categories
4. **Images**: 3 image upload slots
   - First image: Thumbnail (required)
   - Second image: Optional
   - Third image: Optional
5. **GLB File**: 3D model file upload (required)
6. **Specifications**: Dynamic key-value pairs
   - Label and Value fields
   - Add/Remove buttons
7. **Key Features**: Dynamic list of features
   - Text field per feature
   - Add/Remove buttons

### Validation Rules

Before saving, the following validations are performed:

1. **Title**: Must not be empty
2. **Category**: Must be selected
3. **Images**: All 3 images must be uploaded (or have existing URLs)
4. **GLB File**: Must be uploaded (or have existing URL)
5. **Specifications**: At least one specification with both label and value
6. **Key Features**: At least one key feature

### Image Handling

- **New Images**: Uploaded to Supabase Storage
- **Existing Images**: Loaded from URLs when editing
- **Image Preview**: Shows thumbnail before upload
- **Image Removal**: Can remove and re-upload images

### GLB File Handling

- **Upload**: Files uploaded to `products/glb/` path in storage
- **Preview**: Uses `model_viewer_plus` for 3D preview
- **Validation**: Ensures GLB file is uploaded before saving

### Navigation Flow

```
Products Page → Add Product Page → (Save) → Products Page (refreshed)
Products Page → Edit Product → Add Product Page (with data) → (Save) → Products Page (refreshed)
```

---

## 🏷 Category Management

**File**: `lib/widgets/manage_category_dialog.dart`

### Features

- **View Categories**: Display all categories in a scrollable list
- **Add Category**: Add new categories with name validation
- **Edit Category**: Edit existing category names inline
- **Delete Category**: Remove categories from database
- **Duplicate Prevention**: Prevents adding duplicate category names

### Functions

#### `_ManageCategoryDialogState`

##### Initialization
- **`initState()`**: Loads categories from CategoryService
- **`dispose()`**: Cleans up controllers

##### Category Operations
- **`_loadCategories()`**: Fetches categories and deduplicates by name
- **`_addCategory()`**: Adds new category with validation
- **`_startEditing()`**: Enables edit mode for a category
- **`_saveEdit()`**: Saves edited category name
- **`_deleteCategory()`**: Deletes category with confirmation

### UI Components

- **Category List**: Scrollable list with max height
- **Category Row**: Shows name, Edit button, Delete button
- **Edit Mode**: Text field replaces name when editing
- **Add Category**: Text field and Save/Cancel buttons
- **Add New Category Link**: Button to show add form

### Validation

- **Empty Names**: Prevented (trimmed and validated)
- **Duplicates**: Checked both in UI and database
- **Case-Insensitive**: Duplicate check is case-insensitive

### Integration

- Categories synced with Add Product Page via CategoryService
- Changes immediately reflected in category dropdown
- Cache invalidated on add/update/delete

---

## 🔧 Services & Functions

### ProductService

**File**: `lib/services/product_service.dart`

#### Singleton Pattern
- Uses singleton pattern for single instance
- Shared cache across application

#### Functions

##### `preloadProducts()`
- Pre-loads products on app initialization
- Called in `main.dart`

##### `getProducts({bool forceRefresh = false})`
- Fetches products from database
- Returns cached products if available and not expired
- Cache duration: 5 minutes
- **Returns**: `Future<List<Product>>`

##### `getCachedProducts()`
- Returns cached products instantly (synchronous)
- **Returns**: `List<Product>`

##### `invalidateCache()`
- Clears product cache
- Forces next fetch to go to database

##### `getFilteredProducts(String filter)`
- Filters products by status
- **Parameters**: `filter` - "All Products", "Published", or "Draft"
- **Returns**: `Future<List<Product>>`

##### `getProductById(String id)`
- Fetches single product by ID
- **Parameters**: `id` - Product UUID
- **Returns**: `Future<Product?>`

##### `addProduct(Product product)`
- Adds new product to database
- Updates cache with new product
- **Parameters**: `product` - Product object
- **Returns**: `Future<String?>` - Product ID

##### `duplicateProduct(Product product)`
- Creates a copy of product with "(Copy)" suffix
- Sets status to "Draft"
- **Parameters**: `product` - Product to duplicate
- **Returns**: `Future<String?>` - New product ID

##### `updateProduct(String id, Product product)`
- Updates existing product
- Updates cache with fresh data
- Sets `updated_at` timestamp
- **Parameters**: 
  - `id` - Product UUID
  - `product` - Updated product object
- **Returns**: `Future<bool>`

##### `deleteProduct(String id)`
- Deletes product from database
- Removes from cache
- **Parameters**: `id` - Product UUID
- **Returns**: `Future<bool>`

### CategoryService

**File**: `lib/services/category_service.dart`

#### Singleton Pattern
- Uses singleton pattern
- Shared cache across application

#### Functions

##### `getCategories({bool forceRefresh = false})`
- Fetches categories from database
- Seeds default categories if table is empty
- Returns cached categories if available
- Cache duration: 5 minutes
- **Returns**: `Future<List<Category>>`

##### `getCachedCategories()`
- Returns cached categories instantly
- **Returns**: `List<Category>`

##### `invalidateCache()`
- Clears category cache

##### `addCategory(String name)`
- Adds new category
- Prevents duplicates (case-insensitive)
- Returns existing category if duplicate found
- **Parameters**: `name` - Category name
- **Returns**: `Future<Category?>`

##### `updateCategory(String id, String name)`
- Updates category name
- Updates cache
- **Parameters**: 
  - `id` - Category UUID
  - `name` - New category name
- **Returns**: `Future<bool>`

##### `deleteCategory(String id)`
- Deletes category
- Removes from cache
- **Parameters**: `id` - Category UUID
- **Returns**: `Future<bool>`

##### `_insertDefaultCategories()`
- Private method to seed default categories
- Inserts: "Wall Mount", "Portable", "Touch display"

##### `_defaultCategories()`
- Returns fallback categories if database fails
- Used for error handling

### SupabaseService

**File**: `lib/services/supabase_service.dart`

#### Singleton Pattern
- Provides Supabase client instance

#### Functions

##### `initialize({required String supabaseUrl, required String supabaseAnonKey})`
- Static method to initialize Supabase
- Called in `main.dart` before app start
- **Parameters**: 
  - `supabaseUrl` - Supabase project URL
  - `supabaseAnonKey` - Supabase anonymous key

##### `uploadImage({required Uint8List fileBytes, required String fileName, required String bucketName})`
- Uploads image to Supabase Storage
- Path: `products/{fileName}`
- Content type: `image/png`
- **Parameters**: 
  - `fileBytes` - Image file bytes
  - `fileName` - File name with timestamp
  - `bucketName` - Storage bucket name (usually "products")
- **Returns**: `Future<String?>` - Public URL

##### `uploadGlbFile({required Uint8List fileBytes, required String fileName, required String bucketName})`
- Uploads GLB file to Supabase Storage
- Path: `products/glb/{fileName}`
- Content type: `model/gltf-binary`
- **Parameters**: 
  - `fileBytes` - GLB file bytes
  - `fileName` - File name with timestamp
  - `bucketName` - Storage bucket name
- **Returns**: `Future<String?>` - Public URL

##### `deleteFile({required String filePath, required String bucketName})`
- Deletes file from Supabase Storage
- **Parameters**: 
  - `filePath` - File path in storage
  - `bucketName` - Storage bucket name
- **Returns**: `Future<bool>`

---

## 📊 Models & Data Structures

### Product Model

**File**: `lib/models/product.dart`

#### Properties

```dart
class Product {
  final String? id;                    // Database UUID
  final String name;                  // Product name (required)
  final String category;              // Category name (required)
  final String status;                // "Published" or "Draft" (required)
  final String imageUrl;              // Thumbnail image URL (required)
  final String? secondImageUrl;       // Second image URL (optional)
  final String? thirdImageUrl;        // Third image URL (optional)
  final String? glbFileUrl;           // GLB file URL (optional)
  final String? description;           // Product description (optional)
  final List<Map<String, String>>? specifications;  // Key-value pairs
  final List<String>? keyFeatures;     // List of feature strings
  final List<int>? imageBytes;         // Local image bytes (not stored in DB)
  final String? imageDataUrl;          // Local data URL (not stored in DB)
  final DateTime? createdAt;           // Creation timestamp
  final DateTime? updatedAt;           // Last update timestamp
}
```

#### Methods

##### `fromJson(Map<String, dynamic> json)`
- Factory constructor
- Converts database JSON to Product object
- Handles null values gracefully

##### `toJson()`
- Converts Product object to JSON
- Used for database insert/update operations
- Excludes null values

##### `copyWith({...})`
- Creates new Product with updated fields
- Used for immutable updates

### Category Model

**File**: `lib/models/category.dart`

#### Properties

```dart
class Category {
  final String id;      // Database UUID
  final String name;    // Category name
}
```

#### Methods

##### `fromJson(Map<String, dynamic> json)`
- Factory constructor
- Converts database JSON to Category object

##### `toJson()`
- Converts Category object to JSON

##### `copyWith({String? id, String? name})`
- Creates new Category with updated fields

---

## 🔄 Data Flow Examples

### Adding a Product

```
User fills form → Click "Publish" → Validate fields → Upload images → Upload GLB → 
Create Product object → ProductService.addProduct() → Supabase insert → 
Update cache → Navigate back → Products page refreshes
```

### Editing a Product

```
Click edit icon → Navigate with product → Fetch latest from DB → Load form → 
User edits → Click "Publish" → Validate → Upload new files (if any) → 
ProductService.updateProduct() → Supabase update → Update cache → 
Navigate back → Products page refreshes
```

### Real-time Dashboard Updates

```
Supabase Stream → StreamBuilder → Parse products → Calculate metrics → 
Update UI → (Auto-updates on DB changes)
```

---

## 🎨 UI/UX Features

### Responsive Design
- **Mobile**: Stacked layouts, drawer navigation
- **Tablet**: Grid layouts, optimized spacing
- **Desktop**: Horizontal layouts, full feature set

### Loading States
- Instant display from cache
- Background refresh without blocking
- Loading indicators during file uploads
- Progress feedback for long operations

### Error Handling
- User-friendly error messages
- Graceful fallback to cached data
- Validation feedback on forms
- Confirmation dialogs for destructive actions

### User Feedback
- Success/error SnackBars
- Loading dialogs for async operations
- Confirmation dialogs for delete operations
- Real-time UI updates

---

## 📝 Notes

- All timestamps are stored in ISO 8601 format
- Images are stored with timestamp prefixes to prevent conflicts
- GLB files are stored in a separate `glb/` subdirectory
- Cache is automatically invalidated on mutations
- Real-time updates only on Dashboard page
- Products page uses polling/refresh strategy

