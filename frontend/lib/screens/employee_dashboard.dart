import 'package:flutter/material.dart';
import '../services/api.dart';
import '../services/session.dart';
import '../widgets/app_shell.dart';
import '../widgets/stat_card.dart';

class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({super.key});

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _tasks = [];
  List<dynamic> _products = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = ApiService();
      final tasksData = await api.get('/tasks');
      final productsData = await api.get('/products');

      if (!mounted) return;
      setState(() {
        _tasks = tasksData as List<dynamic>;
        _products = productsData as List<dynamic>;
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
        _errorMessage = 'Failed to load employee console: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _completeTask(String taskId) async {
    try {
      await ApiService().put('/tasks/$taskId/complete', {});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task marked as completed!'), backgroundColor: Color(0xFF168B45)),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error completing task: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = Session();

    final pendingTasks = _tasks.where((t) => t['status'] != 'COMPLETED').length;
    final expiredCount = _products.where((p) => p['expiryStatus'] == 'EXPIRED').length;
    final criticalCount = _products.where((p) => p['expiryStatus'] == 'CRITICAL').length;
    final lowStockCount = _products.where((p) {
      final qty = (p['quantity'] as num?)?.toInt() ?? 0;
      final min = (p['minimumStock'] as num?)?.toInt() ?? 0;
      return qty <= min;
    }).length;

    return AppShell(
      title: 'Store Staff Portal',
      selectedIndex: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Color(0xFF168B45)),
          tooltip: 'Refresh',
          onPressed: _loadData,
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
                      ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Employee Duty Board: ${session.name ?? "Store Staff"}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 4),
                      Text('Assigned Store: ${session.storeName ?? "FreshGuard Supermarket #101"} • Daily Checklist',
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                      const SizedBox(height: 24),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          int crossAxisCount = 4;
                          if (constraints.maxWidth < 600) {
                            crossAxisCount = 1;
                          } else if (constraints.maxWidth < 1100) {
                            crossAxisCount = 2;
                          }
                          return GridView.count(
                            crossAxisCount: crossAxisCount,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            mainAxisExtent: 140,
                            children: [
                              StatCard(
                                title: 'Active Tasks',
                                value: '$pendingTasks',
                                subtitle: '${_tasks.length} total tasks assigned',
                                icon: Icons.assignment_outlined,
                                color: const Color(0xFF0284C7),
                              ),
                              StatCard(
                                title: 'Items Expired on Shelf',
                                value: '$expiredCount',
                                subtitle: 'Dispose immediately',
                                icon: Icons.delete_forever,
                                color: const Color(0xFFEF4444),
                              ),
                              StatCard(
                                title: 'Expiring Soon (<7 Days)',
                                value: '$criticalCount',
                                subtitle: 'Triage to front shelf',
                                icon: Icons.alarm,
                                color: const Color(0xFFD97706),
                              ),
                              StatCard(
                                title: 'Low Stock Items',
                                value: '$lowStockCount',
                                subtitle: 'Shelf restock needed',
                                icon: Icons.warning_amber_rounded,
                                color: const Color(0xFF168B45),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Assigned Tasks Checklist',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 12),
                      if (_tasks.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: const Center(
                            child: Column(
                              children: [
                                Icon(Icons.check_circle_outline, color: Color(0xFF168B45), size: 48),
                                SizedBox(height: 12),
                                Text('All operational duties are up to date! No pending tasks.',
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _tasks.length,
                            separatorBuilder: (_, _) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final t = _tasks[index];
                              final isCompleted = t['status'] == 'COMPLETED';

                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(
                                      isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                                      color: isCompleted ? const Color(0xFF168B45) : const Color(0xFFD97706),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            t['title'] ?? 'Task',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              decoration: isCompleted ? TextDecoration.lineThrough : null,
                                            ),
                                          ),
                                          if (t['description'] != null && (t['description'] as String).isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(t['description'], style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    isCompleted
                                        ? const Chip(
                                            label: Text('DONE', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                                            backgroundColor: Color(0xFF168B45),
                                          )
                                        : ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF168B45),
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            ),
                                            onPressed: () => _completeTask(t['id']),
                                            child: const Text('Mark Done', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                          ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
