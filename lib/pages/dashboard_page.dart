import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/sidebar.dart';
import '../widgets/footer.dart';
import '../models/product.dart';
import '../services/supabase_service.dart';
import '../services/analytics_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Timer? _timer;
  final List<_DeletedProduct> _deletedProducts = [];
  final AnalyticsService _analyticsService = AnalyticsService();
  
  // Realtime stream of products from Supabase
  final _productsStream = SupabaseService()
      .client
      .from('products')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false);
  
  // Analytics stream - uses periodic refresh with AnalyticsService methods
  Stream<Map<String, int>> _analyticsStream() async* {
    try {
      // Emit immediately
      yield await _loadAnalyticsData();
      
      // Then emit every 5 seconds
      await for (final _ in Stream.periodic(const Duration(seconds: 5))) {
        yield await _loadAnalyticsData();
      }
    } catch (e) {
      yield {'productViews': 0, 'arViews': 0};
    }
  }
  
  Future<Map<String, int>> _loadAnalyticsData() async {
    final productViews = await _analyticsService.getProductPageViews(days: 30);
    final arViews = await _analyticsService.getARViews(days: 30);
    return {
      'productViews': productViews,
      'arViews': arViews,
    };
  }

  @override
  void initState() {
    super.initState();
    // Update time display every minute for real-time updates
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {
          // Trigger rebuild to update time displays
        });
      }
    });
    
    // Listen for DELETE events to track deleted products
    _setupDeleteListener();
  }
  
  
  void _setupDeleteListener() {
    final channel = SupabaseService().client
        .channel('products_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'products',
          callback: (payload) {
            if (mounted && payload.oldRecord != null) {
              final deletedData = payload.oldRecord as Map<String, dynamic>;
              final deletedProduct = Product.fromJson(deletedData);
              setState(() {
                _deletedProducts.insert(0, _DeletedProduct(
                  product: deletedProduct,
                  deletedAt: DateTime.now(),
                ));
                // Keep only the 3 most recent deletions
                if (_deletedProducts.length > 3) {
                  _deletedProducts.removeRange(3, _deletedProducts.length);
                }
              });
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _timer?.cancel();
    SupabaseService().client.removeAllChannels();
    super.dispose();
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
              child: Sidebar(currentRoute: '/dashboard'),
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
            body: _buildContent(context),
          );
        }
        
        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          body: Stack(
            children: [
              Row(
                children: [
                  const Sidebar(currentRoute: '/dashboard'),
                  Expanded(
                    child: _buildContent(context),
                  ),
                ],
              ),
              // Top-left logo
              Positioned(
                top: 24,
                left: 24,
                child: Image.asset(
                  'assets/images/image.png',
                  height: 60,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            // Static header and metrics section
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dashboard',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Metric Cards - Static, uses stream data but doesn't shift layout
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _productsStream,
                      builder: (context, productsSnapshot) {
                        final products = productsSnapshot.data != null
                            ? productsSnapshot.data!
                                .map((row) => Product.fromJson(row))
                                .toList()
                            : <Product>[];
                        final productCount = products.length;
                        
                        // Combine products stream with analytics stream for real-time updates
                        return StreamBuilder<Map<String, int>>(
                          stream: _analyticsStream(),
                          builder: (context, analyticsSnapshot) {
                            // Handle stream errors
                            if (analyticsSnapshot.hasError) {
                              print('Analytics stream error: ${analyticsSnapshot.error}');
                            }
                            
                            final counts = analyticsSnapshot.data ?? {'productViews': 0, 'arViews': 0};
                            final productViews = counts['productViews'] ?? 0;
                            final arViews = counts['arViews'] ?? 0;
                            
                            return LayoutBuilder(
                              builder: (context, constraints) {
                                final isMobile = constraints.maxWidth < 768;
                                final isTablet = constraints.maxWidth < 1024;

                                final cards = _buildMetricCards(productCount, productViews, arViews);

                                if (isMobile) {
                                  return Column(children: cards);
                                } else if (isTablet) {
                                  return GridView.count(
                                    crossAxisCount: 2,
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 2.5,
                                    children: cards,
                                  );
                                } else {
                                  return Row(
                                    children: cards
                                        .asMap()
                                        .entries
                                        .map((entry) {
                                          final index = entry.key;
                                          final card = entry.value;
                                          return Expanded(
                                            child: Padding(
                                              padding: EdgeInsets.only(
                                                right: index < cards.length - 1 ? 16 : 0,
                                              ),
                                              child: card,
                                            ),
                                          );
                                        })
                                        .toList(),
                                  );
                                }
                              },
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    // Recent Activity - Dynamic section
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _productsStream,
                      builder: (context, snapshot) {
                        final isLoading = snapshot.connectionState == ConnectionState.waiting &&
                            !snapshot.hasData;

                        final products = snapshot.data != null
                            ? snapshot.data!
                                .map((row) => Product.fromJson(row))
                                .toList()
                            : <Product>[];

                        // Sort by most recent activity (updated_at or created_at)
                        products.sort((a, b) {
                          final aTime = a.updatedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                          final bTime = b.updatedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                          return bTime.compareTo(aTime);
                        });

                        // Combine active products and deleted products, then sort by time
                        final List<_ActivityItem> allActivities = [];
                        
                        // Add active products
                        for (final product in products) {
                          allActivities.add(_ActivityItem(
                            product: product,
                            isDeleted: false,
                            activityTime: product.updatedAt ?? product.createdAt ?? DateTime.now(),
                          ));
                        }
                        
                        // Add deleted products
                        for (final deleted in _deletedProducts) {
                          allActivities.add(_ActivityItem(
                            product: deleted.product,
                            isDeleted: true,
                            activityTime: deleted.deletedAt,
                          ));
                        }
                        
                        // Sort all activities by time (most recent first)
                        allActivities.sort((a, b) => b.activityTime.compareTo(a.activityTime));
                        
                        // Take top 3 most recent activities
                        final recentActivities = allActivities.take(3).toList();

                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.refresh,
                                    color: Color(0xFFDC2626),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Recent Activity',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              if (isLoading)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              else if (recentActivities.isEmpty)
                                const Text(
                                  'No recent activity yet.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF6B7280),
                                  ),
                                )
                              else
                                ...recentActivities.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final activity = entry.value;
                                  return Column(
                                    children: [
                                      if (index > 0) const Divider(height: 32),
                                      _TimeAgoWidget(
                                        dateTime: activity.activityTime,
                                        product: activity.product,
                                        isDeleted: activity.isDeleted,
                                      ),
                                    ],
                                  );
                                }),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
        const Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Footer(),
        ),
      ],
    );
  }

  List<Widget> _buildMetricCards(int productCount, int productViews, int arViews) {
    // Format numbers with commas
    String formatNumber(int number) {
      return number.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
    }

    return [
      _buildMetricCard(
        icon: Icons.inventory_2,
        title: 'Product Count',
        value: productCount.toString(),
        trend: 'Total',
        trendColor: Colors.green,
        trendIcon: Icons.trending_up,
      ),
      _buildMetricCard(
        icon: Icons.remove_red_eye,
        title: 'Product Views',
        value: formatNumber(productViews),
        trend: 'Last 30 days',
        trendColor: Colors.blue,
        trendIcon: Icons.visibility,
      ),
      _buildMetricCard(
        icon: Icons.view_in_ar,
        title: 'AR Views',
        value: formatNumber(arViews),
        trend: 'Last 30 days',
        trendColor: Colors.purple,
        trendIcon: Icons.view_in_ar,
      ),
    ];
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required String value,
    required String trend,
    required Color trendColor,
    required IconData trendIcon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFFDC2626),
                  size: 24,
                ),
              ),
              const Icon(
                Icons.info_outline,
                color: Color(0xFF9CA3AF),
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    trendIcon,
                    color: trendColor,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    trend,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: trendColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Helper class to track deleted products
class _DeletedProduct {
  final Product product;
  final DateTime deletedAt;

  _DeletedProduct({
    required this.product,
    required this.deletedAt,
  });
}

// Helper class to represent activity items
class _ActivityItem {
  final Product product;
  final bool isDeleted;
  final DateTime activityTime;

  _ActivityItem({
    required this.product,
    required this.isDeleted,
    required this.activityTime,
  });
}

// Widget that updates time display in real-time
class _TimeAgoWidget extends StatefulWidget {
  final DateTime? dateTime;
  final Product product;
  final bool isDeleted;

  const _TimeAgoWidget({
    required this.dateTime,
    required this.product,
    this.isDeleted = false,
  });

  @override
  State<_TimeAgoWidget> createState() => _TimeAgoWidgetState();
}

class _TimeAgoWidgetState extends State<_TimeAgoWidget> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Update every minute for real-time time display
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {
          // Trigger rebuild to update time
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If deleted, show "Deleted" status
    if (widget.isDeleted) {
      final statusColor = const Color(0xFFDC2626);
      final statusBgColor = const Color(0xFFFEE2E2);
      
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.product.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.product.category,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Deleted',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _formatTimeAgo(widget.dateTime),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ],
      );
    }
    
    final status = widget.product.status;
    final isDraft = status.toLowerCase() == 'draft';
    final statusColor = isDraft ? const Color(0xFF6B7280) : const Color(0xFF16A34A);
    final statusBgColor =
        isDraft ? const Color(0xFFF3F4F6) : const Color(0xECFDF3);

    final timeText = _formatTimeAgo(widget.dateTime);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.product.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.product.category,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusBgColor,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: statusColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              timeText,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final diff = now.difference(dateTime);

    // Less than 1 minute
    if (diff.inSeconds < 60) {
      return 'Just now';
    }
    
    // Less than 1 hour - show minutes
    if (diff.inMinutes < 60) {
      final minutes = diff.inMinutes;
      return '$minutes ${minutes == 1 ? 'min' : 'mins'} ago';
    }
    
    // Less than 24 hours - show hours
    if (diff.inHours < 24) {
      final hours = diff.inHours;
      return '$hours ${hours == 1 ? 'hr' : 'hrs'} ago';
    }
    
    // Less than 30 days - show days
    if (diff.inDays < 30) {
      final days = diff.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    }
    
    // 30 days or more - show months
    final months = (diff.inDays / 30).floor();
    if (months < 12) {
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    }
    
    // 12 months or more - show years
    final years = (diff.inDays / 365).floor();
    return '$years ${years == 1 ? 'year' : 'years'} ago';
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
        return const SizedBox(height: 60);
      },
    ),
  );
}
