# Supabase Setup Guide

Complete guide to setting up and configuring Supabase for the REDWOLF MEDIA Admin Panel.

## 📑 Table of Contents

- [Overview](#overview)
- [Project Setup](#project-setup)
- [Database Schema](#database-schema)
- [Table Creation](#table-creation)
- [Row Level Security (RLS)](#row-level-security-rls)
- [Storage Setup](#storage-setup)
- [API Configuration](#api-configuration)
- [SQL Scripts](#sql-scripts)

---

## 🎯 Overview

This guide covers the complete Supabase setup required for the admin panel, including:
- Database tables (products, categories)
- Row Level Security policies
- Storage buckets for images and GLB files
- Real-time subscriptions

---

## 🚀 Project Setup

### Step 1: Create Supabase Project

1. Go to [supabase.com](https://supabase.com)
2. Sign up or log in
3. Click "New Project"
4. Fill in project details:
   - **Name**: REDWOLF Admin Panel (or your preferred name)
   - **Database Password**: Choose a strong password
   - **Region**: Select closest region
5. Wait for project to be created (2-3 minutes)

### Step 2: Get Project Credentials

1. Go to **Settings** → **API**
2. Copy the following:
   - **Project URL**: `https://your-project.supabase.co`
   - **anon/public key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`
3. Update `lib/main.dart` with these credentials

---

## 📊 Database Schema

### Products Table

Stores all product information including images, GLB files, specifications, and key features.

**Table Name**: `products`

| Column Name | Type | Constraints | Description |
|------------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY, DEFAULT uuid_generate_v4() | Unique product identifier |
| `name` | TEXT | NOT NULL | Product name |
| `category` | TEXT | NOT NULL | Product category |
| `status` | TEXT | NOT NULL | "Published" or "Draft" |
| `image_url` | TEXT | | Thumbnail image URL |
| `second_image_url` | TEXT | | Second image URL (optional) |
| `third_image_url` | TEXT | | Third image URL (optional) |
| `glb_file_url` | TEXT | | GLB 3D model file URL |
| `description` | TEXT | | Product description |
| `specifications` | JSONB | | Array of key-value pairs |
| `key_features` | JSONB | | Array of feature strings |
| `created_at` | TIMESTAMPTZ | DEFAULT now() | Creation timestamp |
| `updated_at` | TIMESTAMPTZ | DEFAULT now() | Last update timestamp |

### Categories Table

Stores product categories with automatic default seeding.

**Table Name**: `categories`

| Column Name | Type | Constraints | Description |
|------------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY, DEFAULT uuid_generate_v4() | Unique category identifier |
| `name` | TEXT | NOT NULL, UNIQUE | Category name |

---

## 🗄 Table Creation

### Step 1: Enable UUID Extension

Run this SQL in the Supabase SQL Editor:

```sql
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
```

### Step 2: Create Categories Table

```sql
-- Create categories table
CREATE TABLE IF NOT EXISTS public.categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL UNIQUE,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Create index on name for faster lookups
CREATE INDEX IF NOT EXISTS idx_categories_name ON public.categories(name);
```

### Step 3: Create Products Table

```sql
-- Create products table
CREATE TABLE IF NOT EXISTS public.products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('Published', 'Draft')),
    image_url TEXT,
    second_image_url TEXT,
    third_image_url TEXT,
    glb_file_url TEXT,
    description TEXT,
    specifications JSONB,
    key_features JSONB,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_products_category ON public.products(category);
CREATE INDEX IF NOT EXISTS idx_products_status ON public.products(status);
CREATE INDEX IF NOT EXISTS idx_products_created_at ON public.products(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_products_updated_at ON public.products(updated_at DESC);
```

### Step 4: Create Updated At Trigger

Automatically updates `updated_at` timestamp on row updates:

```sql
-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to automatically update updated_at
CREATE TRIGGER update_products_updated_at
    BEFORE UPDATE ON public.products
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
```

### Step 5: Seed Default Categories

```sql
-- Insert default categories (only if they don't exist)
INSERT INTO public.categories (name)
SELECT 'Wall Mount'
WHERE NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Wall Mount');

INSERT INTO public.categories (name)
SELECT 'Portable'
WHERE NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Portable');

INSERT INTO public.categories (name)
SELECT 'Touch display'
WHERE NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Touch display');
```

---

## 🔒 Row Level Security (RLS)

Row Level Security policies control who can read, insert, update, and delete data.

### Enable RLS on Tables

```sql
-- Enable RLS on categories table
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

-- Enable RLS on products table
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
```

### Categories Table Policies

#### Allow Public Read Access

```sql
-- Policy: Anyone can read categories
CREATE POLICY "Categories are viewable by everyone"
ON public.categories
FOR SELECT
USING (true);
```

#### Allow Authenticated Users to Manage Categories

```sql
-- Policy: Authenticated users can insert categories
CREATE POLICY "Authenticated users can insert categories"
ON public.categories
FOR INSERT
WITH CHECK (auth.role() = 'authenticated');

-- Policy: Authenticated users can update categories
CREATE POLICY "Authenticated users can update categories"
ON public.categories
FOR UPDATE
USING (auth.role() = 'authenticated')
WITH CHECK (auth.role() = 'authenticated');

-- Policy: Authenticated users can delete categories
CREATE POLICY "Authenticated users can delete categories"
ON public.categories
FOR DELETE
USING (auth.role() = 'authenticated');
```

**Note**: For development/testing, you can use anonymous access:

```sql
-- Development: Allow anonymous access (NOT RECOMMENDED FOR PRODUCTION)
CREATE POLICY "Allow anonymous access to categories"
ON public.categories
FOR ALL
USING (true)
WITH CHECK (true);
```

### Products Table Policies

#### Allow Public Read Access

```sql
-- Policy: Anyone can read products
CREATE POLICY "Products are viewable by everyone"
ON public.products
FOR SELECT
USING (true);
```

#### Allow Authenticated Users to Manage Products

```sql
-- Policy: Authenticated users can insert products
CREATE POLICY "Authenticated users can insert products"
ON public.products
FOR INSERT
WITH CHECK (auth.role() = 'authenticated');

-- Policy: Authenticated users can update products
CREATE POLICY "Authenticated users can update products"
ON public.products
FOR UPDATE
USING (auth.role() = 'authenticated')
WITH CHECK (auth.role() = 'authenticated');

-- Policy: Authenticated users can delete products
CREATE POLICY "Authenticated users can delete products"
ON public.products
FOR DELETE
USING (auth.role() = 'authenticated');
```

**Note**: For development/testing with anonymous access:

```sql
-- Development: Allow anonymous access (NOT RECOMMENDED FOR PRODUCTION)
CREATE POLICY "Allow anonymous access to products"
ON public.products
FOR ALL
USING (true)
WITH CHECK (true);
```

---

## 📦 Storage Setup

### Step 1: Create Storage Bucket

1. Go to **Storage** in Supabase dashboard
2. Click **New Bucket**
3. Configure bucket:
   - **Name**: `products`
   - **Public bucket**: ✅ Enable (checked)
   - **File size limit**: 50 MB (or your preference)
   - **Allowed MIME types**: Leave empty for all types

### Step 2: Configure Storage Policies

#### Allow Public Read Access

```sql
-- Policy: Anyone can read files from products bucket
CREATE POLICY "Public Access"
ON storage.objects
FOR SELECT
USING (bucket_id = 'products');
```

#### Allow Authenticated Users to Upload

```sql
-- Policy: Authenticated users can upload files
CREATE POLICY "Authenticated users can upload"
ON storage.objects
FOR INSERT
WITH CHECK (
    bucket_id = 'products' AND
    auth.role() = 'authenticated'
);
```

#### Allow Authenticated Users to Update/Delete

```sql
-- Policy: Authenticated users can update files
CREATE POLICY "Authenticated users can update"
ON storage.objects
FOR UPDATE
USING (
    bucket_id = 'products' AND
    auth.role() = 'authenticated'
)
WITH CHECK (
    bucket_id = 'products' AND
    auth.role() = 'authenticated'
);

-- Policy: Authenticated users can delete files
CREATE POLICY "Authenticated users can delete"
ON storage.objects
FOR DELETE
USING (
    bucket_id = 'products' AND
    auth.role() = 'authenticated'
);
```

**Note**: For development with anonymous access:

```sql
-- Development: Allow anonymous uploads (NOT RECOMMENDED FOR PRODUCTION)
CREATE POLICY "Allow anonymous uploads"
ON storage.objects
FOR ALL
USING (bucket_id = 'products')
WITH CHECK (bucket_id = 'products');
```

### Step 3: Storage Folder Structure

Files are organized as follows:

```
products/
├── thumbnail_1234567890_image1.png
├── image2_1234567890_image2.png
├── image3_1234567890_image3.png
└── glb/
    └── model_1234567890_product.glb
```

---

## ⚙️ API Configuration

### Real-time Subscriptions

The dashboard uses real-time subscriptions to automatically update when products change.

#### Enable Real-time on Products Table

1. Go to **Database** → **Replication**
2. Find `products` table
3. Enable replication by toggling the switch

Or via SQL:

```sql
-- Enable real-time replication for products table
ALTER PUBLICATION supabase_realtime ADD TABLE public.products;
```

**Note**: Real-time is enabled by default for new tables in Supabase.

---

## 📝 Complete SQL Scripts

### All-in-One Setup Script

Run this complete script in the Supabase SQL Editor to set up everything:

```sql
-- ============================================
-- REDWOLF ADMIN PANEL - SUPABASE SETUP
-- ============================================

-- Step 1: Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Step 2: Create categories table
CREATE TABLE IF NOT EXISTS public.categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL UNIQUE,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_categories_name ON public.categories(name);

-- Step 3: Create products table
CREATE TABLE IF NOT EXISTS public.products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('Published', 'Draft')),
    image_url TEXT,
    second_image_url TEXT,
    third_image_url TEXT,
    glb_file_url TEXT,
    description TEXT,
    specifications JSONB,
    key_features JSONB,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_products_category ON public.products(category);
CREATE INDEX IF NOT EXISTS idx_products_status ON public.products(status);
CREATE INDEX IF NOT EXISTS idx_products_created_at ON public.products(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_products_updated_at ON public.products(updated_at DESC);

-- Step 4: Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Step 5: Create trigger for updated_at
DROP TRIGGER IF EXISTS update_products_updated_at ON public.products;
CREATE TRIGGER update_products_updated_at
    BEFORE UPDATE ON public.products
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Step 6: Seed default categories
INSERT INTO public.categories (name)
SELECT 'Wall Mount'
WHERE NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Wall Mount');

INSERT INTO public.categories (name)
SELECT 'Portable'
WHERE NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Portable');

INSERT INTO public.categories (name)
SELECT 'Touch display'
WHERE NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Touch display');

-- Step 7: Enable RLS
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

-- Step 8: Drop existing policies (if any)
DROP POLICY IF EXISTS "Categories are viewable by everyone" ON public.categories;
DROP POLICY IF EXISTS "Allow anonymous access to categories" ON public.categories;
DROP POLICY IF EXISTS "Products are viewable by everyone" ON public.products;
DROP POLICY IF EXISTS "Allow anonymous access to products" ON public.products;

-- Step 9: Create RLS policies for categories
-- Public read access
CREATE POLICY "Categories are viewable by everyone"
ON public.categories
FOR SELECT
USING (true);

-- Anonymous full access (for development - REMOVE IN PRODUCTION)
CREATE POLICY "Allow anonymous access to categories"
ON public.categories
FOR ALL
USING (true)
WITH CHECK (true);

-- Step 10: Create RLS policies for products
-- Public read access
CREATE POLICY "Products are viewable by everyone"
ON public.products
FOR SELECT
USING (true);

-- Anonymous full access (for development - REMOVE IN PRODUCTION)
CREATE POLICY "Allow anonymous access to products"
ON public.products
FOR ALL
USING (true)
WITH CHECK (true);

-- Step 11: Enable real-time replication
ALTER PUBLICATION supabase_realtime ADD TABLE public.products;
```

### Storage Policies Script

Run this in the SQL Editor after creating the storage bucket:

```sql
-- ============================================
-- STORAGE POLICIES SETUP
-- ============================================

-- Drop existing policies (if any)
DROP POLICY IF EXISTS "Public Access" ON storage.objects;
DROP POLICY IF EXISTS "Allow anonymous uploads" ON storage.objects;

-- Public read access
CREATE POLICY "Public Access"
ON storage.objects
FOR SELECT
USING (bucket_id = 'products');

-- Anonymous full access (for development - REMOVE IN PRODUCTION)
CREATE POLICY "Allow anonymous uploads"
ON storage.objects
FOR ALL
USING (bucket_id = 'products')
WITH CHECK (bucket_id = 'products');
```

---

## 🔍 Verification

### Verify Tables Created

Run this query to verify tables exist:

```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('products', 'categories');
```

### Verify Default Categories

```sql
SELECT * FROM public.categories ORDER BY name;
```

Expected result:
- Wall Mount
- Portable
- Touch display

### Verify RLS Enabled

```sql
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('products', 'categories');
```

Both should show `rowsecurity = true`.

### Verify Storage Bucket

1. Go to **Storage** → **Buckets**
2. Verify `products` bucket exists
3. Check that it's marked as **Public**

### Test Real-time

1. Insert a test product:
```sql
INSERT INTO public.products (name, category, status, image_url)
VALUES ('Test Product', 'Wall Mount', 'Draft', 'https://example.com/image.png');
```

2. Check if it appears in the dashboard (should update automatically)

---

## 🔐 Production Security Checklist

Before deploying to production:

- [ ] Remove anonymous access policies
- [ ] Implement proper authentication
- [ ] Set up service role key for admin operations
- [ ] Configure CORS policies
- [ ] Set up backup strategy
- [ ] Enable database backups
- [ ] Review and tighten RLS policies
- [ ] Set appropriate file size limits
- [ ] Configure rate limiting
- [ ] Set up monitoring and alerts

---

## 🐛 Troubleshooting

### Issue: "Could not find the table 'public.products'"

**Solution**: Run the table creation SQL scripts in order.

### Issue: "new row violates row-level security policy"

**Solution**: Check RLS policies are correctly set up. For development, use anonymous access policies.

### Issue: "permission denied for storage.objects"

**Solution**: Ensure storage bucket policies are created and bucket is public.

### Issue: Real-time not working

**Solution**: 
1. Verify real-time replication is enabled in Database → Replication
2. Check that `supabase_realtime` publication includes the table

### Issue: Images not loading

**Solution**:
1. Verify storage bucket is public
2. Check storage policies allow public read access
3. Verify image URLs are correct format

---

## 📚 Additional Resources

- [Supabase Documentation](https://supabase.com/docs)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Row Level Security Guide](https://supabase.com/docs/guides/auth/row-level-security)
- [Storage Guide](https://supabase.com/docs/guides/storage)

---

## 📝 Notes

- All timestamps use `TIMESTAMPTZ` for timezone-aware storage
- UUIDs are generated automatically using `uuid_generate_v4()`
- JSONB columns allow efficient querying of nested data
- Indexes improve query performance for filtered searches
- Real-time subscriptions require WebSocket connection

---

**Last Updated**: See git commit history for latest changes.
