import 'package:flutter/material.dart';
import '../services/api.dart';
import '../widgets/app_shell.dart';

class DiscountsScreen extends StatefulWidget {
  const DiscountsScreen({super.key});

  @override
  State<DiscountsScreen> createState() => _DiscountsScreenState();
}

class _DiscountsScreenState extends State<DiscountsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _suggestions = [];
  List<dynamic> _discounts = [];
  List<dynamic> _products = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = ApiService();
      final suggestionsFuture = api.getDiscountSuggestions();
      final discountsFuture = api.getDiscounts();
      final productsFuture = api.getProducts();

      final results = await Future.wait([suggestionsFuture, discountsFuture, productsFuture]);

      if (!mounted) return;
      setState(() {
        _suggestions = results[0];
        _discounts = results[1];
        _products = results[2];
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
        _errorMessage = 'Failed to load discount data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _applySuggestion(Map<String, dynamic> item) async {
    try {
      final productId = item['productId'] ?? item['id'];
      final percent = ((item['suggestedDiscountPercent'] ?? item['suggestedDiscount']) as num?)?.toDouble() ?? 20.0;
      final reason = item['ruleReason'] ?? item['reason'] ?? 'Near-expiry markdown suggestion';

      await ApiService().createDiscount(productId, percent, reason);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Discount created for ${item['productName'] ?? "Item"}!'),
          backgroundColor: const Color(0xFF168B45),
        ),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to apply discount: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _approveDiscount(String id) async {
    try {
      await ApiService().approveDiscount(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Discount approved successfully!'), backgroundColor: Color(0xFF168B45)),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Approval failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _rejectDiscount(String id) async {
    try {
      await ApiService().rejectDiscount(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Discount rejected'), backgroundColor: Colors.orange),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rejection failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showCreateCustomDiscountDialog() {
    if (_products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No products available to discount')),
      );
      return;
    }

    String selectedProductId = _products.first['id'];
    final percentCtrl = TextEditingController(text: '20');
    final reasonCtrl = TextEditingController(text: 'Manager promotional clearance');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Create Custom Markdown'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedProductId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Select Product'),
                  items: _products.map<DropdownMenuItem<String>>((p) {
                    return DropdownMenuItem<String>(
                      value: p['id'].toString(),
                      child: Text(
                        '${p['name']} (₹${p['price'] ?? 0})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setDlgState(() => selectedProductId = v ?? selectedProductId),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: percentCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Discount Percentage (%)',
                    suffixText: '%',
                    hintText: 'e.g. 25',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: reasonCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Markdown Rationale',
                    hintText: 'e.g. Clearance sale for near-expiry products',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final pct = double.tryParse(percentCtrl.text.trim());
                if (pct == null || pct <= 0 || pct > 90) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a percentage between 1 and 90%')),
                  );
                  return;
                }
                Navigator.pop(ctx);
                try {
                  await ApiService().createDiscount(
                    selectedProductId,
                    pct,
                    reasonCtrl.text.trim(),
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Discount created!'), backgroundColor: Color(0xFF168B45)),
                  );
                  _loadData();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Create Discount'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsTab() {
    if (_suggestions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified, size: 54, color: Color(0xFF168B45)),
              const SizedBox(height: 16),
              const Text('No Urgent Discount Suggestions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              const SizedBox(height: 6),
              Text(
                'All near-expiry products currently have discounts applied or are outside markdown threshold.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _suggestions.length,
      itemBuilder: (context, index) {
        final item = _suggestions[index];
        final days = (item['daysUntilExpiry'] as num?)?.toInt() ?? 0;
        final currentPrice = (item['currentPrice'] as num?)?.toDouble() ?? 0.0;
        final discountPercent = ((item['suggestedDiscountPercent'] ?? item['suggestedDiscount']) as num?)?.toDouble() ?? 0.0;
        final discountedPrice = ((item['discountedPrice'] ?? item['suggestedPrice']) as num?)?.toDouble() ?? (currentPrice * (1 - discountPercent / 100));

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
                        item['productName'] ?? 'Item',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706).withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFD97706)),
                      ),
                      child: Text(
                        'Suggest ${discountPercent.toStringAsFixed(0)}% OFF',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD97706), fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Barcode: ${item['barcode'] ?? "N/A"} • Category: ${item['category'] ?? "General"}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '₹${currentPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Color(0xFF94A3B8),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '₹${discountedPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF168B45),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      days <= 0 ? 'EXPIRED' : '$days days until expiry',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: days <= 7 ? const Color(0xFFEF4444) : const Color(0xFFD97706),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    'Rule Trigger: ${item['ruleReason'] ?? "Approaching expiry threshold"}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF168B45),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Apply Markdown', style: TextStyle(fontSize: 13)),
                    onPressed: () => _applySuggestion(item),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDiscountsTab() {
    if (_discounts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.percent, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text('No discount records created yet',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _discounts.length,
      itemBuilder: (context, index) {
        final d = _discounts[index];
        final status = (d['status'] as String?)?.toUpperCase() ?? 'PENDING';
        final percent = (d['percentage'] as num?)?.toDouble() ?? 0.0;
        final isPending = status == 'PENDING';

        Color badgeColor = const Color(0xFFD97706);
        if (status == 'APPROVED') badgeColor = const Color(0xFF168B45);
        if (status == 'REJECTED') badgeColor = const Color(0xFFEF4444);

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
                        d['productName'] ?? 'Discount #${d['id']}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: badgeColor),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${percent.toStringAsFixed(0)}% Markdown • Created by: ${d['createdBy'] ?? "Staff"}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF168B45)),
                ),
                if (d['reason'] != null) ...[
                  const SizedBox(height: 4),
                  Text('Rationale: ${d['reason']}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
                if (isPending) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
                          onPressed: () => _rejectDiscount(d['id']),
                          child: const Text('Reject'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF168B45), foregroundColor: Colors.white),
                          onPressed: () => _approveDiscount(d['id']),
                          child: const Text('Approve'),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Discounts Management',
      selectedIndex: 6,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Color(0xFF168B45)),
          tooltip: 'Refresh',
          onPressed: _loadData,
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF168B45),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Create Markdown'),
        onPressed: _showCreateCustomDiscountDialog,
      ),
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
              : Column(
                  children: [
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Smart Expiry Markdown Rules',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Automated mathematical discount rules to accelerate sales for items nearing end-of-shelf-life.',
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
                              Tab(text: 'Rule Suggestions (${_suggestions.length})'),
                              Tab(text: 'Active / Past Discounts (${_discounts.length})'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildSuggestionsTab(),
                          _buildDiscountsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
