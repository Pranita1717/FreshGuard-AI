import 'package:flutter/material.dart';
import '../services/api.dart';
import '../widgets/app_shell.dart';

class ShelfPriorityScreen extends StatefulWidget {
  const ShelfPriorityScreen({super.key});

  @override
  State<ShelfPriorityScreen> createState() => _ShelfPriorityScreenState();
}

class _ShelfPriorityScreenState extends State<ShelfPriorityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _products = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadProducts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await ApiService().getProducts();
      if (!mounted) return;
      setState(() {
        _products = data;
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
        _errorMessage = 'Failed to load shelf triage data: $e';
        _isLoading = false;
      });
    }
  }

  List<dynamic> _filterByPriority(String priority) {
    if (priority == 'ALL') {
      return _products.where((p) => (p['expiryStatus'] ?? 'SAFE') != 'REMOVED').toList();
    }
    return _products.where((p) {
      if ((p['expiryStatus'] ?? 'SAFE') == 'REMOVED') return false;
      final status = (p['expiryStatus'] as String?)?.toUpperCase() ?? 'SAFE';
      if (priority == 'HIGH') {
        return status == 'EXPIRED' || status == 'CRITICAL';
      } else if (priority == 'MEDIUM') {
        return status == 'NEAR_EXPIRY';
      } else if (priority == 'LOW') {
        return status == 'SAFE';
      }
      return false;
    }).toList();
  }

  void _showAdjustStockDialog(Map<String, dynamic> product) {
    final qtyCtrl = TextEditingController(text: '${product['quantity'] ?? 0}');
    final reasonCtrl = TextEditingController(text: 'Shelf priority triage adjustment');
    String action = 'SET';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: Text('Adjust Stock: ${product['name']}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current Quantity: ${product['quantity']} ${product['unit'] ?? "units"}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: action,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Action Type'),
                  items: const [
                    DropdownMenuItem(value: 'SET', child: Text('Set Exact Shelf Count')),
                    DropdownMenuItem(value: 'INCREASE', child: Text('Add Restock Units (+)')),
                    DropdownMenuItem(value: 'DECREASE', child: Text('Reduce / Damaged (-)')),
                  ],
                  onChanged: (v) => setDlgState(() => action = v ?? 'SET'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: action == 'SET' ? 'New Total Count' : 'Quantity Units',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonCtrl,
                  decoration: const InputDecoration(labelText: 'Audit Reason'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final qty = int.tryParse(qtyCtrl.text.trim());
                if (qty == null || qty < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid non-negative number')),
                  );
                  return;
                }
                Navigator.pop(ctx);
                try {
                  await ApiService().updateInventory(
                    product['id'],
                    action,
                    qty,
                    reasonCtrl.text.trim(),
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Shelf inventory updated successfully!'),
                      backgroundColor: Color(0xFF168B45),
                    ),
                  );
                  _loadProducts();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating stock: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(String status, int? days) {
    Color color;
    String label;
    IconData icon;

    if (status == 'EXPIRED' || (days != null && days < 0)) {
      color = const Color(0xFFEF4444);
      label = 'HIGH: EXPIRED';
      icon = Icons.cancel;
    } else if (status == 'CRITICAL' || (days != null && days <= 7)) {
      color = const Color(0xFFDC2626);
      label = 'HIGH: CRITICAL (≤7d)';
      icon = Icons.priority_high;
    } else if (status == 'NEAR_EXPIRY' || (days != null && days <= 30)) {
      color = const Color(0xFFD97706);
      label = 'MEDIUM: NEAR EXPIRY (8-30d)';
      icon = Icons.warning_amber_rounded;
    } else {
      color = const Color(0xFF168B45);
      label = 'LOW: SAFE (>30d)';
      icon = Icons.check_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildShelfRuleExplanation(String status, int? days) {
    String rule;
    String action;
    Color bg;

    if (status == 'EXPIRED') {
      rule = 'Rule: daysRemaining < 0 => Expired';
      action = 'ACTION: Remove immediately from shelves into disposal bin.';
      bg = const Color(0xFFFEF2F2);
    } else if (status == 'CRITICAL' || (days != null && days <= 7)) {
      rule = 'Rule: 0 ≤ daysRemaining ≤ 7 => Critical Tier';
      action = 'ACTION: Move to front of eye-level shelf (FIFO). Apply markdown discount.';
      bg = const Color(0xFFFFFBEB);
    } else if (status == 'NEAR_EXPIRY' || (days != null && days <= 30)) {
      rule = 'Rule: 8 ≤ daysRemaining ≤ 30 => Near Expiry';
      action = 'ACTION: Rotate behind critical items. Monitor daily stock movement.';
      bg = const Color(0xFFF0FDF4);
    } else {
      rule = 'Rule: daysRemaining > 30 => Safe Tier';
      action = 'ACTION: Standard rear shelf storage. Keep fresh stock protected.';
      bg = const Color(0xFFF8FAFC);
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(rule, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
          const SizedBox(height: 2),
          Text(action, style: const TextStyle(fontSize: 11, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _buildProductList(List<dynamic> list) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inventory, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text('No products in this priority tier',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final p = list[index];
        final status = (p['expiryStatus'] as String?)?.toUpperCase() ?? 'SAFE';
        final days = (p['daysUntilExpiry'] as num?)?.toInt();
        final qty = p['quantity'] ?? 0;
        final unit = p['unit'] ?? 'units';

        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p['name'] ?? 'Product',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Category: ${p['category']} • Barcode: ${p['barcode']}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    _buildPriorityBadge(status, days),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('Expiry: ${p['expiryDate'] ?? "N/A"}',
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                    if (days != null)
                      Text(
                        days < 0 ? '(${days.abs()} days overdue)' : '($days days remaining)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: days <= 7 ? const Color(0xFFEF4444) : const Color(0xFF168B45),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF168B45).withAlpha(15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Stock: $qty $unit',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF168B45), fontSize: 13),
                      ),
                    ),
                  ],
                ),
                _buildShelfRuleExplanation(status, days),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF168B45),
                          side: const BorderSide(color: Color(0xFF168B45)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        icon: const Icon(Icons.edit_note, size: 16),
                        label: const Text('Adjust Shelf Stock', style: TextStyle(fontSize: 12)),
                        onPressed: () => _showAdjustStockDialog(p),
                      ),
                      if (status == 'CRITICAL' || status == 'NEAR_EXPIRY')
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD97706),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          icon: const Icon(Icons.percent, size: 16),
                          label: const Text('Apply Markdown', style: TextStyle(fontSize: 12)),
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/manager/discounts');
                          },
                        ),
                      if (status == 'EXPIRED')
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          icon: const Icon(Icons.delete_forever, size: 16),
                          label: const Text('Disposal Protocol', style: TextStyle(fontSize: 12)),
                          onPressed: () {
                            Navigator.pushNamed(context, '/employee/remove-expired');
                          },
                        ),
                    ],
                  ),
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
    final highItems = _filterByPriority('HIGH');
    final mediumItems = _filterByPriority('MEDIUM');
    final lowItems = _filterByPriority('LOW');
    final allItems = _filterByPriority('ALL');

    return AppShell(
      title: 'Shelf Priority Triage',
      selectedIndex: 5,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Color(0xFF168B45)),
          tooltip: 'Refresh',
          onPressed: _loadProducts,
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
                      ElevatedButton(onPressed: _loadProducts, child: const Text('Retry')),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Rule-Based Shelf Priority Triage',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Products are sorted strictly by date arithmetic rules (FIFO) to minimize store spoilage and customer risk.',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                          ),
                          const SizedBox(height: 14),
                          TabBar(
                            controller: _tabController,
                            indicatorColor: const Color(0xFF168B45),
                            labelColor: const Color(0xFF168B45),
                            unselectedLabelColor: const Color(0xFF64748B),
                            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            tabs: [
                              Tab(text: 'High Priority (${highItems.length})'),
                              Tab(text: 'Medium Priority (${mediumItems.length})'),
                              Tab(text: 'Low Priority (${lowItems.length})'),
                              Tab(text: 'All Items (${allItems.length})'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildProductList(highItems),
                          _buildProductList(mediumItems),
                          _buildProductList(lowItems),
                          _buildProductList(allItems),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
