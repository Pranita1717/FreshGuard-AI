import 'package:flutter/material.dart';
import '../services/session.dart';

class AppShell extends StatelessWidget {
  final String title;
  final Widget body;
  final int selectedIndex;
  final Function(int)? onDestinationSelected;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const AppShell({
    super.key,
    required this.title,
    required this.body,
    this.selectedIndex = 0,
    this.onDestinationSelected,
    this.actions,
    this.floatingActionButton,
  });

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to end your session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await Session().clearSession();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Color _getRoleBadgeColor(String? role) {
    switch (role) {
      case 'ADMIN':
        return const Color(0xFF8B5CF6);
      case 'STORE_MANAGER':
        return const Color(0xFF168B45);
      case 'EMPLOYEE':
        return const Color(0xFF0284C7);
      default:
        return Colors.grey;
    }
  }

  String _formatRoleLabel(String? role) {
    switch (role) {
      case 'ADMIN':
        return 'ADMINISTRATOR';
      case 'STORE_MANAGER':
        return 'STORE MANAGER';
      case 'EMPLOYEE':
        return 'STORE STAFF';
      default:
        return role ?? 'USER';
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = Session();
    final role = session.role;
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1024;
    final isMobile = width < 650;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: isDesktop
            ? null
            : Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu, color: Color(0xFF1E293B)),
                  tooltip: 'Open Navigation Menu',
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
        title: isMobile
            ? Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontWeight: FontWeight.bold,
                      fontSize: 19,
                    ),
                  ),
                  if (session.isLoggedIn && (session.name != null || session.storeName != null))
                    Text(
                      'Welcome back, ${session.name ?? "Staff"} • ${session.storeName ?? "FreshGuard Store"}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                ],
              ),
        actions: [
          if (session.isLoggedIn) ...[
            if (!isMobile) ...[
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getRoleBadgeColor(role).withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _getRoleBadgeColor(role).withAlpha(80)),
                ),
                child: Center(
                  child: Text(
                    _formatRoleLabel(role),
                    style: TextStyle(
                      color: _getRoleBadgeColor(role),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // Operational Notifications icon (Only for Store Manager and Employee)
              if (role == 'STORE_MANAGER' || role == 'EMPLOYEE')
                IconButton(
                  icon: const Icon(Icons.notifications_none, color: Color(0xFF64748B)),
                  tooltip: 'Operational Notifications',
                  onPressed: () {
                    final target = role == 'STORE_MANAGER' ? '/manager/notifications' : '/employee/notifications';
                    if (ModalRoute.of(context)?.settings.name != target) {
                      Navigator.of(context).pushNamed(target);
                    }
                  },
                ),
              IconButton(
                icon: const Icon(Icons.person_outline, color: Color(0xFF64748B)),
                tooltip: 'Profile & Settings',
                onPressed: () => Navigator.of(context).pushNamed('/settings'),
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Color(0xFF64748B)),
                tooltip: 'Logout',
                onPressed: () => _handleLogout(context),
              ),
            ] else ...[
              // On mobile, show notification bell only if no other screen actions to keep top-bar uncluttered
              if ((actions == null || actions!.isEmpty) && (role == 'STORE_MANAGER' || role == 'EMPLOYEE'))
                IconButton(
                  icon: const Icon(Icons.notifications_none, color: Color(0xFF64748B)),
                  tooltip: 'Operational Notifications',
                  onPressed: () {
                    final target = role == 'STORE_MANAGER' ? '/manager/notifications' : '/employee/notifications';
                    if (ModalRoute.of(context)?.settings.name != target) {
                      Navigator.of(context).pushNamed(target);
                    }
                  },
                ),
            ],
          ],
          if (actions != null) ...actions!,
        ],
      ),
      drawer: isDesktop ? null : _buildDrawer(context),
      body: Row(
        children: [
          if (isDesktop && session.isLoggedIn) _buildSidebar(context),
          Expanded(child: body),
        ],
      ),
      floatingActionButton: floatingActionButton,
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          _buildBrandHeader(),
          const Divider(height: 1),
          Expanded(child: _buildNavList(context)),
          const Divider(height: 1),
          _buildUserProfile(context),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          _buildBrandHeader(),
          const Divider(height: 1),
          Expanded(child: _buildNavList(context)),
          const Divider(height: 1),
          _buildUserProfile(context),
        ],
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF168B45),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.shield, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'FRESHGUARD',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 0.8,
                    color: Color(0xFF0B6B35),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Expiry & Inventory System',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavList(BuildContext context) {
    final session = Session();
    final role = session.role;

    if (role == 'ADMIN') {
      return ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _navItem(context, Icons.dashboard, 'Dashboard', '/admin', selectedIndex == 0),
          _navItem(context, Icons.analytics_outlined, 'System Analytics', '/admin/analytics', selectedIndex == 1),
          _navItemAction(context, Icons.logout, 'Logout', () => _handleLogout(context)),
        ],
      );
    } else if (role == 'STORE_MANAGER') {
      return ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _navItem(context, Icons.dashboard, 'Dashboard', '/manager', selectedIndex == 0),
          _navItem(context, Icons.assignment_add, 'Assign Tasks', '/manager/tasks', selectedIndex == 1),
          _navItem(context, Icons.inventory_2_outlined, 'Inventory Management', '/manager/inventory', selectedIndex == 2),
          _navItem(context, Icons.qr_code_scanner, 'Scan Product', '/manager/barcode', selectedIndex == 3),
          _navItem(context, Icons.document_scanner_outlined, 'OCR Expiry Detection', '/manager/ocr', selectedIndex == 4),
          _navItem(context, Icons.low_priority, 'Shelf Priority', '/manager/shelf-priority', selectedIndex == 5),
          _navItem(context, Icons.percent, 'Discount Suggestions', '/manager/discounts', selectedIndex == 6),
          _navItem(context, Icons.local_shipping_outlined, 'Restocking Prediction', '/manager/restocking', selectedIndex == 7),
          _navItem(context, Icons.notifications_none, 'Notifications', '/manager/notifications', selectedIndex == 8),
          _navItem(context, Icons.picture_as_pdf_outlined, 'Reports', '/manager/reports', selectedIndex == 9),
          _navItem(context, Icons.settings_outlined, 'Settings', '/settings', selectedIndex == 10),
          _navItemAction(context, Icons.logout, 'Logout', () => _handleLogout(context)),
        ],
      );
    } else {
      return ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _navItem(context, Icons.dashboard, 'Dashboard', '/employee', selectedIndex == 0),
          _navItem(context, Icons.assignment_outlined, 'My Tasks', '/employee/tasks', selectedIndex == 1),
          _navItem(context, Icons.qr_code_scanner, 'Scan Product', '/employee/scanner', selectedIndex == 2),
          _navItem(context, Icons.edit_note, 'Update Inventory', '/employee/inventory', selectedIndex == 3),
          _navItem(context, Icons.delete_sweep_outlined, 'Remove Expired Products', '/employee/remove-expired', selectedIndex == 4),
          _navItem(context, Icons.notifications_none, 'Notifications', '/employee/notifications', selectedIndex == 5),
          _navItem(context, Icons.person_outline, 'Profile', '/settings', selectedIndex == 6),
          _navItemAction(context, Icons.logout, 'Logout', () => _handleLogout(context)),
        ],
      );
    }
  }

  Widget _navItem(BuildContext context, IconData icon, String title, String route, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Builder(
        builder: (tileContext) => ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          leading: Icon(
            icon,
            color: isSelected ? const Color(0xFF168B45) : const Color(0xFF64748B),
            size: 20,
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? const Color(0xFF168B45) : const Color(0xFF334155),
            ),
          ),
          tileColor: isSelected ? const Color(0xFF168B45).withAlpha(20) : Colors.transparent,
          onTap: () {
            final scaffold = Scaffold.maybeOf(tileContext);
            if (scaffold?.isDrawerOpen == true) {
              Navigator.of(tileContext).pop();
            }
            if (ModalRoute.of(tileContext)?.settings.name != route) {
              Navigator.of(tileContext).pushReplacementNamed(route);
            }
          },
        ),
      ),
    );
  }

  Widget _navItemAction(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Builder(
        builder: (tileContext) => ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          leading: Icon(icon, color: const Color(0xFFEF4444), size: 20),
          title: Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFFEF4444)),
          ),
          onTap: () {
            final scaffold = Scaffold.maybeOf(tileContext);
            if (scaffold?.isDrawerOpen == true) {
              Navigator.of(tileContext).pop();
            }
            onTap();
          },
        ),
      ),
    );
  }

  Widget _buildUserProfile(BuildContext context) {
    final session = Session();
    return InkWell(
      onTap: () => Navigator.of(context).pushNamed('/settings'),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF168B45).withAlpha(40),
              child: Text(
                (session.name != null && session.name!.isNotEmpty) ? session.name![0].toUpperCase() : 'U',
                style: const TextStyle(color: Color(0xFF168B45), fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    session.name ?? 'Staff User',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    session.storeName ?? 'FreshGuard Store',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}
