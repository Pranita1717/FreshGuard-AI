import 'package:flutter/material.dart';
import '../services/api.dart';
import '../services/session.dart';
import '../widgets/app_shell.dart';

class EmployeeTasksScreen extends StatefulWidget {
  const EmployeeTasksScreen({super.key});

  @override
  State<EmployeeTasksScreen> createState() => _EmployeeTasksScreenState();
}

class _EmployeeTasksScreenState extends State<EmployeeTasksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _tasks = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await ApiService().getTasks();
      if (!mounted) return;
      setState(() {
        _tasks = data;
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
        _errorMessage = 'Failed to load task board: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(String taskId, String newStatus) async {
    try {
      if (newStatus == 'COMPLETED') {
        await ApiService().completeTask(taskId);
      } else {
        await ApiService().updateTaskStatus(taskId, newStatus);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task updated to $newStatus!'),
          backgroundColor: const Color(0xFF168B45),
        ),
      );
      _loadTasks();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  List<dynamic> _filterTasks(String status) {
    if (status == 'ALL') return _tasks;
    return _tasks.where((t) => (t['status'] as String?)?.toUpperCase() == status).toList();
  }

  Color _getPriorityColor(String? priority) {
    switch (priority?.toUpperCase()) {
      case 'HIGH':
        return const Color(0xFFEF4444);
      case 'MEDIUM':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF168B45);
    }
  }

  Widget _buildTaskList(List<dynamic> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_turned_in, size: 52, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text('No tasks in this category',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF64748B))),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final t = list[index];
        final status = (t['status'] as String?)?.toUpperCase() ?? 'PENDING';
        final priority = (t['priority'] as String?)?.toUpperCase() ?? 'MEDIUM';
        final pColor = _getPriorityColor(priority);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        t['title'] ?? 'Operational Duty',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                          decoration: status == 'COMPLETED' ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: pColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: pColor.withAlpha(80)),
                      ),
                      child: Text(
                        priority,
                        style: TextStyle(color: pColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                if (t['description'] != null && (t['description'] as String).isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(t['description'], style: const TextStyle(color: Color(0xFF475569), fontSize: 13)),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    Text('Assigned to: ${t['assignedTo'] ?? "Staff"}',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                    if (status == 'PENDING')
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.play_arrow, size: 16),
                        label: const Text('Start Duty', style: TextStyle(fontSize: 12)),
                        onPressed: () => _updateStatus(t['id'], 'IN_PROGRESS'),
                      )
                    else if (status == 'IN_PROGRESS')
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF168B45),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Mark Complete', style: TextStyle(fontSize: 12)),
                        onPressed: () => _updateStatus(t['id'], 'COMPLETED'),
                      )
                    else
                      const Chip(
                        label: Text('COMPLETED', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                        backgroundColor: Color(0xFF168B45),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = _filterTasks('PENDING');
    final inProgress = _filterTasks('IN_PROGRESS');
    final completed = _filterTasks('COMPLETED');
    final all = _tasks;

    return AppShell(
      title: 'Duty & Task Board',
      selectedIndex: 1,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Color(0xFF168B45)),
          tooltip: 'Refresh',
          onPressed: _loadTasks,
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
                      ElevatedButton(onPressed: _loadTasks, child: const Text('Retry')),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      color: Colors.white,
                      child: TabBar(
                        controller: _tabController,
                        indicatorColor: const Color(0xFF168B45),
                        labelColor: const Color(0xFF168B45),
                        unselectedLabelColor: const Color(0xFF64748B),
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        tabs: [
                          Tab(text: 'Pending (${pending.length})'),
                          Tab(text: 'In Progress (${inProgress.length})'),
                          Tab(text: 'Done (${completed.length})'),
                          Tab(text: 'All (${all.length})'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildTaskList(pending),
                          _buildTaskList(inProgress),
                          _buildTaskList(completed),
                          _buildTaskList(all),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
