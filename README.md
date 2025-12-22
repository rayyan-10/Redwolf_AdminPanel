# REDWOLF MEDIA - Admin Panel

A comprehensive Flutter-based admin panel for managing products with 3D AR capabilities, integrated with Supabase for backend services.

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Configuration](#configuration)
- [Architecture](#architecture)
- [Documentation](#documentation)

## 🎯 Overview

The REDWOLF MEDIA Admin Panel is a web-based administration system designed to manage product catalogs with support for:
- Product management (CRUD operations)
- Category management
- Image uploads (3 images per product)
- 3D GLB file uploads for AR visualization
- Real-time dashboard with product statistics
- Product status management (Published/Draft)

## ✨ Features

### Core Functionality
- **Product Management**: Create, read, update, and delete products
- **Category Management**: Dynamic category system with default seeding
- **File Uploads**: Support for multiple images and 3D GLB files
- **Real-time Updates**: Dashboard updates in real-time using Supabase streams
- **Search & Filter**: Search products by name, category, or description
- **Status Management**: Publish or save products as drafts
- **Product Duplication**: Quick duplicate functionality for similar products

### User Interface
- **Responsive Design**: Works on mobile, tablet, and desktop
- **Modern UI**: Clean, professional interface with consistent styling
- **Real-time Dashboard**: Live product count and recent activity feed
- **Intuitive Navigation**: Sidebar navigation with active route highlighting

## 🛠 Tech Stack

### Frontend
- **Flutter**: Cross-platform UI framework
- **GoRouter**: Declarative routing
- **Material Design 3**: Modern UI components

### Backend & Services
- **Supabase**: Backend-as-a-Service (BaaS)
  - PostgreSQL database
  - Storage for images and GLB files
  - Real-time subscriptions
  - Row Level Security (RLS)

### Key Packages
- `supabase_flutter`: Supabase integration
- `go_router`: Navigation and routing
- `file_picker`: File selection
- `model_viewer_plus`: 3D model preview
- `http`: HTTP requests for image loading

## 📁 Project Structure

```
lib/
├── main.dart                 # Application entry point and routing
├── models/                   # Data models
│   ├── product.dart         # Product data model
│   └── category.dart        # Category data model
├── services/                 # Business logic and API services
│   ├── supabase_service.dart    # Supabase client and file operations
│   ├── product_service.dart     # Product CRUD operations
│   └── category_service.dart    # Category CRUD operations
├── pages/                    # Application screens
│   ├── login_page.dart      # Login/authentication page
│   ├── dashboard_page.dart  # Dashboard with metrics and activity
│   ├── products_page.dart   # Product listing and management
│   └── add_product_page.dart    # Add/Edit product form
└── widgets/                  # Reusable UI components
    ├── sidebar.dart         # Navigation sidebar
    ├── footer.dart         # Application footer
    └── manage_category_dialog.dart  # Category management dialog
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK
- Supabase account and project
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd REDWOLF
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Supabase**
   - Create a Supabase project at [supabase.com](https://supabase.com)
   - Get your project URL and anon key
   - Update `lib/main.dart` with your credentials:
     ```dart
     await SupabaseService.initialize(
       supabaseUrl: 'YOUR_SUPABASE_URL',
       supabaseAnonKey: 'YOUR_SUPABASE_ANON_KEY',
     );
     ```

4. **Set up Supabase Database**
   - See [SUPABASE_SETUP.md](./SUPABASE_SETUP.md) for detailed database setup instructions
   - Run the SQL scripts to create tables and set up RLS policies

5. **Set up Supabase Storage**
   - Create a storage bucket named `products`
   - Configure public access for the bucket
   - See [SUPABASE_SETUP.md](./SUPABASE_SETUP.md) for details

6. **Run the application**
   ```bash
   flutter run -d chrome
   ```

## ⚙️ Configuration

### Supabase Configuration

Update the Supabase credentials in `lib/main.dart`:

```dart
await SupabaseService.initialize(
  supabaseUrl: 'https://your-project.supabase.co',
  supabaseAnonKey: 'your-anon-key',
);
```

### Storage Bucket

Ensure you have a storage bucket named `products` in your Supabase project with:
- Public access enabled
- File size limits configured (recommended: 10MB for images, 50MB for GLB files)

## 🏗 Architecture

### Service Layer Pattern

The application follows a service-oriented architecture:

1. **SupabaseService**: Low-level Supabase client wrapper
   - Handles file uploads (images and GLB files)
   - Provides Supabase client instance

2. **ProductService**: Product business logic
   - CRUD operations for products
   - Caching mechanism (5-minute cache duration)
   - Cache invalidation on updates

3. **CategoryService**: Category business logic
   - CRUD operations for categories
   - Default category seeding
   - Duplicate prevention

### State Management

- **StatefulWidget**: Used for local component state
- **StreamBuilder**: Real-time data updates (Dashboard)
- **Caching**: In-memory caching for performance

### Data Flow

```
User Action → Page Widget → Service Layer → Supabase → Database/Storage
                ↓
         Update UI State
```

## 📚 Documentation

For detailed documentation, see:

- **[ADMIN_PANEL_GUIDE.md](./ADMIN_PANEL_GUIDE.md)**: Complete guide to admin panel features and functionality
- **[SUPABASE_SETUP.md](./SUPABASE_SETUP.md)**: Supabase database and storage setup instructions

## 🔐 Security

- Row Level Security (RLS) policies are enforced in Supabase
- Authentication handled through Supabase Auth (currently using simple login flow)
- File uploads validated before storage
- Input validation on all forms

## 🚧 Development Notes

### Caching Strategy
- Products cached for 5 minutes
- Cache invalidated on create/update/delete operations
- Fallback to cached data on network errors

### Error Handling
- Try-catch blocks in all service methods
- User-friendly error messages via SnackBars
- Graceful degradation (shows cached data on errors)

### Performance Optimizations
- Lazy loading of images
- Cached product lists for instant display
- Background refresh without blocking UI
- Efficient real-time subscriptions

## 📝 License

Built by Ruditech

## 🤝 Support

For issues or questions, contact the development team.

---

**Note**: This is an admin panel for managing products. Ensure proper authentication and authorization are implemented before production deployment.
