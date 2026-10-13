import 'package:flutter/material.dart';
import '../services/api.dart';
import '../services/session.dart';
import '../widgets/app_shell.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _notifications = [];
  String _filter = 'ALL';

  @override
  void initState() {
    super.initState();
    if (Session().role != 'ADMIN') {
      _loadNotifications();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await ApiService().getNotifications();
      if (!mounted) return;
      setState(() {
        _notifications = data;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load notifications: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _markRead(String id) async {
    try {
      await ApiService().markNotificationRead(id);
      _loadNotifications();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update alert: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _markAllRead() async {
    try {
      await ApiService().markAllNotificationsRead();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All alerts marked as read!'),
          backgroundColor: Color(0xFF168B45),
        ),
      );
      _loadNotifications();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  List<dynamic> _getFilteredNotifications() {
    if (_filter == 'UNREAD') {
      return _notifications.where((n) => n['isRead'] != true).toList();
    } else if (_filter == 'CRITICAL') {
      return _notifications.where((n) => (n['type'] as String?)?.toUpperCase() == 'CRITICAL').toList();
    }
    return _notifications;
  }

  Color _getTypeColor(String? type) {
    switch (type?.toUpperCase()) {
      case 'CRITICAL':
      case 'DANGER':
      case 'EXPIRED':
        return const Color(0xFFEF4444);
      case 'WARNING':
      case 'NEAR_EXPIRY':
      case 'LOW_STOCK':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF0284C7);
    }
  }

  IconData _getTypeIcon(String? type) {
    switch (type?.toUpperCase()) {
      case 'CRITICAL':
      case 'DANGER':
      case 'EXPIRED':
        return Icons.dangerous;
      case 'WARNING':
      case 'NEAR_EXPIRY':
      case 'LOW_STOCK':
        return Icons.warning_amber_rounded;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredNotifications();
    final unreadCount = _notifications.where((n) => n['isRead'] != true).length;

    final session = Session();
    if (session.role == 'ADMIN') {
      return AppShell(
        title: 'Operational Notifications',
        selectedIndex: -1,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shield_outlined, size: 56, color: Color(0xFFD97706)),
                const SizedBox(height: 16),
                const Text(
                  'Access Restricted to Store Operations',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Operational inventory notifications (Low stock alerts, shelf expiry warnings, disposal tasks) are assigned exclusively to Store Managers and Store Employees.\n\nAdministrative monitoring and application analytics are available on the Admin Dashboard.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF168B45),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.dashboard),
                  label: const Text('Return to Admin Dashboard'),
                  onPressed: () => Navigator.of(context).pushReplacementNamed('/admin'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final navIndex = session.role == 'EMPLOYEE' ? 5 : 8;

    return AppShell(
      title: 'Alerts & Notifications',
      selectedIndex: navIndex,
      actions: [
        if (unreadCount > 0)
          IconButton(
            icon: const Icon(Icons.done_all, color: Color(0xFF168B45)),
            tooltip: 'Mark All Read',
            onPressed: _markAllRead,
          ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Color(0xFF168B45)),
          tooltip: 'Refresh',
          onPressed: _loadNotifications,
        ),
      ],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF168B45)))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _loadNotifications, child: const Text('Retry')),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ChoiceChip(
                              label: Text('All (${_notifications.length})'),
                              selected: _filter == 'ALL',
                              selectedColor: const Color(0xFF168B45),
                              labelStyle: TextStyle(color: _filter == 'ALL' ? Colors.white : Colors.black87),
                              onSelected: (_) => setState(() => _filter = 'ALL'),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: Text('Unread ($unreadCount)'),
                              selected: _filter == 'UNREAD',
                              selectedColor: const Color(0xFF168B45),
                              labelStyle: TextStyle(color: _filter == 'UNREAD' ? Colors.white : Colors.black87),
                              onSelected: (_) => setState(() => _filter = 'UNREAD'),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Critical Alerts'),
                              selected: _filter == 'CRITICAL',
                              selectedColor: const Color(0xFFEF4444),
                              labelStyle: TextStyle(color: _filter == 'CRITICAL' ? Colors.white : Colors.black87),
                              onSelected: (_) => setState(() => _filter = 'CRITICAL'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.notifications_none, size: 54, color: Colors.grey.shade400),
                                  const SizedBox(height: 12),
                                  const Text('No alerts found',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final n = filtered[index];
                                final isRead = n['isRead'] == true;
                                final type = n['type'] as String?;
                                final color = _getTypeColor(type);
                                final icon = _getTypeIcon(type);

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  color: isRead ? Colors.white : const Color(0xFFF0FDF4),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    leading: CircleAvatar(
                                      backgroundColor: color.withAlpha(25),
                                      child: Icon(icon, color: color),
                                    ),
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            n['title'] ?? 'Alert',
                                            style: TextStyle(
                                              fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                              fontSize: 15,
                                              color: const Color(0xFF0F172A),
                                            ),
                                          ),
                                        ),
                                        if (!isRead)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF168B45),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 6),
                                        Text(
                                          n['message'] ?? '',
                                          style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              n['createdAt'] ?? '',
                                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                            ),
                                            if (!isRead)
                                              TextButton(
                                                style: TextButton.styleFrom(
                                                  padding: EdgeInsets.zero,
                                                  minimumSize: const Size(60, 24),
                                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                ),
                                                onPressed: () => _markRead(n['id']),
                                                child: const Text('Mark Read', style: TextStyle(fontSize: 12)),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
