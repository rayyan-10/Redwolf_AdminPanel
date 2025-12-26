import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/supabase_service.dart';

class Sidebar extends StatefulWidget {
  final String currentRoute;

  const Sidebar({
    super.key,
    required this.currentRoute,
  });

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  bool _isDashboardHovered = false;
  bool _isProductsHovered = false;
  bool _isLogoutHovered = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      color: Colors.white,
      child: Column(
        children: [
          // Logo Section
          Padding(
            padding: const EdgeInsets.all(24),
            child: _buildLogo(),
          ),
          // Menu Section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Menu',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Navigation Items
          Expanded(
            child: Column(
              children: [
                _buildNavItem(
                  context,
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                  route: '/dashboard',
                  isActive: widget.currentRoute == '/dashboard',
                  isHovered: _isDashboardHovered,
                  onHover: (value) {
                    setState(() {
                      _isDashboardHovered = value;
                    });
                  },
                ),
                const SizedBox(height: 8),
                _buildNavItem(
                  context,
                  icon: Icons.inventory_2_outlined,
                  label: 'Products',
                  route: '/products',
                  isActive: widget.currentRoute == '/products',
                  isHovered: _isProductsHovered,
                  onHover: (value) {
                    setState(() {
                      _isProductsHovered = value;
                    });
                  },
                ),
              ],
            ),
          ),
          // Logout
          Padding(
            padding: const EdgeInsets.all(24),
            child: MouseRegion(
              onEnter: (_) {
                setState(() {
                  _isLogoutHovered = true;
                });
              },
              onExit: (_) {
                setState(() {
                  _isLogoutHovered = false;
                });
              },
              cursor: SystemMouseCursors.click,
              child: InkWell(
                onTap: () async {
                  final supabaseService = SupabaseService();
                  await supabaseService.signOut();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isLogoutHovered
                        ? const Color(0xFFDC2626).withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.arrow_forward,
                        color: Color(0xFFDC2626),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    required bool isActive,
    required bool isHovered,
    required ValueChanged<bool> onHover,
  }) {
    Color getBackgroundColor() {
      if (isActive) {
        return const Color(0xFFDC2626).withValues(alpha: 0.1);
      }
      if (isHovered) {
        return const Color(0xFFF3F4F6);
      }
      return Colors.transparent;
    }

    Color getIconColor() {
      if (isActive) {
        return const Color(0xFFDC2626);
      }
      if (isHovered) {
        return const Color(0xFFDC2626);
      }
      return const Color(0xFF374151);
    }

    Color getTextColor() {
      if (isActive) {
        return const Color(0xFFDC2626);
      }
      if (isHovered) {
        return const Color(0xFFDC2626);
      }
      return const Color(0xFF374151);
    }

    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: () {
          context.go(route);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: getBackgroundColor(),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: getIconColor(),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: getTextColor(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
}

