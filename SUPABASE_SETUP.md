# Supabase Setup Instructions

## 1. Create Supabase Project

1. Go to https://supabase.com and sign up/login
2. Create a new project
3. Note down your project URL and anon key from Settings > API

## 2. Create Database Table

Run this SQL in the Supabase SQL Editor:

```sql
-- Create products table
CREATE TABLE products (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('Draft', 'Published')),
  image_url TEXT NOT NULL,
  second_image_url TEXT,
  glb_file_url TEXT,
  description TEXT,
  specifications JSONB,
  key_features JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX idx_products_status ON products(status);
CREATE INDEX idx_products_category ON products(category);

-- Enable Row Level Security (RLS)
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- Create policy to allow all operations (adjust based on your auth requirements)
CREATE POLICY "Allow all operations" ON products
  FOR ALL
  USING (true)
  WITH CHECK (true);
```

## 3. Create Storage Bucket

1. Go to Storage in Supabase dashboard
2. Create a new bucket named `products`
3. Set it to Public (or configure policies as needed)
4. Add the following storage policies:

```sql
-- Allow public read access
CREATE POLICY "Public Access" ON storage.objects
  FOR SELECT
  USING (bucket_id = 'products');

-- Allow authenticated users to upload
CREATE POLICY "Authenticated users can upload" ON storage.objects
  FOR INSERT
  WITH CHECK (bucket_id = 'products');

-- Allow authenticated users to update
CREATE POLICY "Authenticated users can update" ON storage.objects
  FOR UPDATE
  USING (bucket_id = 'products');

-- Allow authenticated users to delete
CREATE POLICY "Authenticated users can delete" ON storage.objects
  FOR DELETE
  USING (bucket_id = 'products');
```

## 4. Update Flutter App Configuration

1. Open `lib/main.dart`
2. Replace `YOUR_SUPABASE_URL` with your Supabase project URL
3. Replace `YOUR_SUPABASE_ANON_KEY` with your Supabase anon key

Example:
```dart
await SupabaseService.initialize(
  supabaseUrl: 'https://your-project.supabase.co',
  supabaseAnonKey: 'your-anon-key-here',
);
```

## 5. Install Dependencies

Run:
```bash
flutter pub get
```

## 6. Test the Integration

1. Run the app
2. Navigate to Products page
3. Click "Add product"
4. Fill in product details and upload images/GLB file
5. Click "Publish" or "Save Draft"
6. Verify the product appears in the Products page

## Notes

- The storage bucket name is set to `products` in the code
- Images are stored in `products/` folder
- GLB files are stored in `products/glb/` folder
- All file names include timestamps to avoid conflicts

