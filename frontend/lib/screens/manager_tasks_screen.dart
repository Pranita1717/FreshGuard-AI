import 'package:flutter/material.dart';
import '../services/api.dart';
import '../services/session.dart';
import '../widgets/app_shell.dart';

class ManagerTasksScreen extends StatefulWidget {
  const ManagerTasksScreen({super.key});

  @override
  State<ManagerTasksScreen> createState() => _ManagerTasksScreenState();
}

class _ManagerTasksScreenState extends State<ManagerTasksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  bool _employeesLoading = true;
  String? _error;
  List<dynamic> _tasks = [];
  List<dynamic> _employees = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([ApiService().getTasks(), ApiService().getStoreEmployees()]);
      if (!mounted) return;
      setState(() {
        _tasks = results[0];
        _employees = results[1];
        _loading = false;
        _employeesLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'Unable to load store tasks/employees: $e'; _loading = false; _employeesLoading = false; });
    }
  }

  Future<void> _assignTask() async {
    if (_employees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No employees are connected to your store yet.')));
      return;
    }
    final title = TextEditingController();
    final description = TextEditingController();
    String employeeEmail = _employees.first['email']?.toString() ?? '';
    String taskType = 'UPDATE_INVENTORY';
    String priority = 'MEDIUM';
    DateTime? dueDate;

    final assigned = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Row(children: [Icon(Icons.assignment_add, color: Color(0xFF168B45)), SizedBox(width: 10), Text('Assign Task')]),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label('Connected employee'),
                DropdownButtonFormField<String>(
                  value: employeeEmail.isEmpty ? null : employeeEmail,
                  isExpanded: true,
                  items: _employees.map((e) => DropdownMenuItem<String>(value: e['email'].toString(), child: Text('${e['name'] ?? 'Employee'} • ${e['email']}'))).toList(),
                  onChanged: (v) => setDialog(() => employeeEmail = v ?? ''),
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.person_outline), hintText: 'Select employee'),
                ),
                const SizedBox(height: 14),
                _label('Task type'),
                DropdownButtonFormField<String>(
                  value: taskType,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'SCAN_PRODUCT', child: Text('Scan Product')),
                    DropdownMenuItem(value: 'UPDATE_INVENTORY', child: Text('Update Inventory')),
                    DropdownMenuItem(value: 'REMOVE_EXPIRED', child: Text('Remove Expired Products')),
                    DropdownMenuItem(value: 'SHELF_CHECK', child: Text('Shelf Check')),
                    DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                  ],
                  onChanged: (v) => setDialog(() => taskType = v ?? 'OTHER'),
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.category_outlined)),
                ),
                const SizedBox(height: 14),
                TextField(controller: title, decoration: const InputDecoration(labelText: 'Task title *', prefixIcon: Icon(Icons.title))),
                const SizedBox(height: 14),
                TextField(controller: description, maxLines: 3, decoration: const InputDecoration(labelText: 'Instructions / details', prefixIcon: Icon(Icons.notes_outlined))),
                const SizedBox(height: 14),
                _label('Priority'),
                DropdownButtonFormField<String>(
                  value: priority,
                  items: const [DropdownMenuItem(value: 'HIGH', child: Text('High')), DropdownMenuItem(value: 'MEDIUM', child: Text('Medium')), DropdownMenuItem(value: 'LOW', child: Text('Low'))],
                  onChanged: (v) => setDialog(() => priority = v ?? 'MEDIUM'),
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.flag_outlined)),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  icon: const Icon(Icons.event_outlined),
                  label: Text(dueDate == null ? 'Optional due date & time' : 'Due: ${dueDate!.day}/${dueDate!.month}/${dueDate!.year} ${dueDate!.hour.toString().padLeft(2,'0')}:${dueDate!.minute.toString().padLeft(2,'0')}'),
                  onPressed: () async {
                    final d = await showDatePicker(context: ctx, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)), initialDate: DateTime.now());
                    if (d != null) {
                      final t = await showTimePicker(context: ctx, initialTime: TimeOfDay.now());
                      if (t != null) setDialog(() => dueDate = DateTime(d.year, d.month, d.day, t.hour, t.minute));
                    }
                  },
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFF168B45).withAlpha(15), borderRadius: BorderRadius.circular(10)),
                  child: Row(children: [const Icon(Icons.store_outlined, size: 20, color: Color(0xFF168B45)), const SizedBox(width: 8), Expanded(child: Text('Store: ${Session().storeName ?? 'Your store'}\nOnly employees connected to this store are listed.', style: const TextStyle(fontSize: 12, color: Color(0xFF166534))))]),
                ),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton.icon(onPressed: () async {
              if (title.text.trim().isEmpty || employeeEmail.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select an employee and enter a task title.')));
                return;
              }
              try {
                await ApiService().createTask({'title': title.text.trim(), 'description': description.text.trim(), 'assignedTo': employeeEmail, 'taskType': taskType, 'priority': priority, 'dueDate': dueDate?.toIso8601String()});
                if (ctx.mounted) Navigator.pop(ctx, true);
              } catch (e) {
                if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Failed to assign task: $e'), backgroundColor: Colors.red));
              }
            }, icon: const Icon(Icons.send), label: const Text('Assign Task')),
          ],
        ),
      ),
    );
    title.dispose(); description.dispose();
    if (assigned == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task assigned and employee notified.'), backgroundColor: Color(0xFF168B45)));
      _load();
    }
  }

  Widget _label(String s) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(s, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF334155), fontSize: 13)));

  List<dynamic> _filter(String status) => status == 'ALL' ? _tasks : _tasks.where((t) => (t['status'] ?? '').toString().toUpperCase() == status).toList();

  Widget _taskList(List<dynamic> list) {
    if (list.isEmpty) return const Center(child: Text('No tasks in this category.', style: TextStyle(color: Color(0xFF64748B))));
    return ListView.builder(padding: const EdgeInsets.all(16), itemCount: list.length, itemBuilder: (_, i) {
      final t = list[i] as Map<String, dynamic>;
      final status = (t['status'] ?? 'PENDING').toString();
      final priority = (t['priority'] ?? 'MEDIUM').toString();
      final employee = t['assignedTo'] ?? 'Employee';
      return Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text(t['title'] ?? 'Task', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))), Chip(label: Text(priority, style: const TextStyle(fontSize: 10))) ]),
        const SizedBox(height: 6),
        Text(t['taskType'] ?? 'OTHER', style: const TextStyle(color: Color(0xFF168B45), fontWeight: FontWeight.w600, fontSize: 12)),
        if ((t['description'] ?? '').toString().isNotEmpty) ...[const SizedBox(height: 6), Text(t['description'])],
        const SizedBox(height: 10),
        Wrap(spacing: 16, runSpacing: 8, children: [Text('Employee: $employee', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))), Text('Status: $status', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))]),
      ])));
    });
  }

  @override
  Widget build(BuildContext context) {
    final pending = _filter('PENDING'), progress = _filter('IN_PROGRESS'), done = _filter('COMPLETED');
    return AppShell(title: 'Assign & Manage Tasks', selectedIndex: 1, actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh, color: Color(0xFF168B45)))], floatingActionButton: FloatingActionButton.extended(onPressed: _assignTask, backgroundColor: const Color(0xFF168B45), foregroundColor: Colors.white, icon: const Icon(Icons.add_task), label: const Text('Assign Task')), body: _loading ? const Center(child: CircularProgressIndicator(color: Color(0xFF168B45))) : _error != null ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(_error!, style: const TextStyle(color: Colors.red)), const SizedBox(height: 12), ElevatedButton(onPressed: _load, child: const Text('Retry'))])) : Column(children: [
      Container(color: Colors.white, child: TabBar(controller: _tabController, indicatorColor: const Color(0xFF168B45), labelColor: const Color(0xFF168B45), tabs: [Tab(text: 'Pending (${pending.length})'), Tab(text: 'In Progress (${progress.length})'), Tab(text: 'Completed (${done.length})'), Tab(text: 'All (${_tasks.length})')])),
      Expanded(child: TabBarView(controller: _tabController, children: [_taskList(pending), _taskList(progress), _taskList(done), _taskList(_tasks)])),
    ]));
  }
}
