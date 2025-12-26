import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Service for tracking and retrieving analytics data
class AnalyticsService {
  final SupabaseService _supabaseService = SupabaseService();
  SupabaseClient get _client => _supabaseService.client;

  /// Track a product page view
  Future<void> trackProductView(String productId) async {
    try {
      await _client.from('analytics').insert({
        'event_type': 'product_view',
        'product_id': productId,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Silently fail - analytics should not break the app
      // Check if error is due to missing table (PGRST205) and ignore it
      final errorString = e.toString();
      if (errorString.contains('PGRST205') || 
          errorString.contains('Could not find the table')) {
        // Table doesn't exist - silently skip analytics
        return;
      }
      // For other errors, log but don't break the app
      print('Error tracking product view: $e');
    }
  }

  /// Track an AR view
  Future<void> trackARView(String productId) async {
    try {
      await _client.from('analytics').insert({
        'event_type': 'ar_view',
        'product_id': productId,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Silently fail - analytics should not break the app
      // Check if error is due to missing table (PGRST205) and ignore it
      final errorString = e.toString();
      if (errorString.contains('PGRST205') || 
          errorString.contains('Could not find the table')) {
        // Table doesn't exist - silently skip analytics
        return;
      }
      // For other errors, log but don't break the app
      print('Error tracking AR view: $e');
    }
  }

  /// Get product page views count for the last N days
  Future<int> getProductPageViews({int days = 30}) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));
      final response = await _client
          .from('analytics')
          .select('id')
          .eq('event_type', 'product_view')
          .gte('created_at', startDate.toIso8601String());

      if (response is List) {
        return response.length;
      }
      return 0;
    } catch (e) {
      // Check if error is due to missing table
      final errorString = e.toString();
      if (errorString.contains('PGRST205') || 
          errorString.contains('Could not find the table')) {
        // Table doesn't exist - return 0
        return 0;
      }
      print('Error fetching product page views: $e');
      return 0;
    }
  }

  /// Get AR views count for the last N days
  Future<int> getARViews({int days = 30}) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));
      final response = await _client
          .from('analytics')
          .select('id')
          .eq('event_type', 'ar_view')
          .gte('created_at', startDate.toIso8601String());

      if (response is List) {
        return response.length;
      }
      return 0;
    } catch (e) {
      // Check if error is due to missing table
      final errorString = e.toString();
      if (errorString.contains('PGRST205') || 
          errorString.contains('Could not find the table')) {
        // Table doesn't exist - return 0
        return 0;
      }
      print('Error fetching AR views: $e');
      return 0;
    }
  }

  /// Get total analytics count (product views + AR views) for the last N days
  Future<int> getTotalViews({int days = 30}) async {
    try {
      final productViews = await getProductPageViews(days: days);
      final arViews = await getARViews(days: days);
      return productViews + arViews;
    } catch (e) {
      print('Error fetching total views: $e');
      return 0;
    }
  }
}











