import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;

  // Initialize Supabase (call this in main.dart)
  static Future<void> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  // Upload image to Supabase Storage
  Future<String?> uploadImage({
    required Uint8List fileBytes,
    required String fileName,
    required String bucketName,
  }) async {
    try {
      final path = 'products/$fileName';
      await client.storage.from(bucketName).uploadBinary(
        path,
        fileBytes,
        fileOptions: const FileOptions(
          contentType: 'image/png',
          upsert: true,
        ),
      );

      // Get public URL
      final url = client.storage.from(bucketName).getPublicUrl(path);
      return url;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Upload GLB file to Supabase Storage
  Future<String?> uploadGlbFile({
    required Uint8List fileBytes,
    required String fileName,
    required String bucketName,
  }) async {
    try {
      final path = 'products/glb/$fileName';
      await client.storage.from(bucketName).uploadBinary(
        path,
        fileBytes,
        fileOptions: const FileOptions(
          contentType: 'model/gltf-binary',
          upsert: true,
        ),
      );

      // Get public URL
      final url = client.storage.from(bucketName).getPublicUrl(path);
      return url;
    } catch (e) {
      print('Error uploading GLB file: $e');
      return null;
    }
  }

  // Upload USDZ file to Supabase Storage (for Apple devices)
  Future<String?> uploadUsdzFile({
    required Uint8List fileBytes,
    required String fileName,
    required String bucketName,
  }) async {
    try {
      final path = 'products/usdz/$fileName';
      await client.storage.from(bucketName).uploadBinary(
        path,
        fileBytes,
        fileOptions: const FileOptions(
          contentType: 'model/vnd.usdz+zip',
          upsert: true,
        ),
      );

      // Get public URL
      final url = client.storage.from(bucketName).getPublicUrl(path);
      return url;
    } catch (e) {
      print('Error uploading USDZ file: $e');
      return null;
    }
  }

  // Delete file from Supabase Storage
  Future<bool> deleteFile({
    required String filePath,
    required String bucketName,
  }) async {
    try {
      await client.storage.from(bucketName).remove([filePath]);
      return true;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }

  // Sign in with email and password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Sign out
  Future<void> signOut() async {
    await client.auth.signOut();
  }

  // Get current user
  User? getCurrentUser() {
    return client.auth.currentUser;
  }

  // Check if user is authenticated
  bool isAuthenticated() {
    return client.auth.currentUser != null;
  }
}

