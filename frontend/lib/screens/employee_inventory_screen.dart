import 'package:flutter/material.dart';
import '../services/api.dart';
import '../widgets/app_shell.dart';

class EmployeeInventoryScreen extends StatefulWidget {
  const EmployeeInventoryScreen({super.key});

  @override
  State<EmployeeInventoryScreen> createState() => _EmployeeInventoryScreenState();
}

class _EmployeeInventoryScreenState extends State<EmployeeInventoryScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _products = [];
  final Map<String, TextEditingController> _controllers = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    for (var ctrl in _controllers.values) {
      ctrl.dispose();
    }
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
        _products = data.where((p) => (p['expiryStatus'] ?? 'SAFE') != 'REMOVED').toList();
        for (var p in _products) {
          final id = p['id'].toString();
          final qty = p['quantity'] ?? 0;
          _controllers[id] = TextEditingController(text: '$qty');
        }
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
        _errorMessage = 'Failed to load stock list: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _syncPhysicalCount(Map<String, dynamic> product) async {
    final id = (product['id'] ?? product['productId'])?.toString() ?? '';
    final ctrl = _controllers[id];
    final text = ctrl?.text.trim() ?? '';

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the counted quantity.')),
      );
      return;
    }

    final newCount = int.tryParse(text);
    if (newCount == null || newCount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid quantity.')),
      );
      return;
    }

    try {
      await ApiService().updateInventory(
        id,
        'SET',
        newCount,
        'Physical shelf count audit performed by staff',
        newQuantity: newCount,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verified and synced ${product['name'] ?? "product"} to $newCount units!'),
          backgroundColor: const Color(0xFF168B45),
        ),
      );
      _loadProducts();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to update inventory. Please check the quantity.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<dynamic> _getFilteredProducts() {
    if (_searchQuery.isEmpty) return _products;
    final q = _searchQuery.toLowerCase();
    return _products.where((p) {
      final name = (p['name'] as String?)?.toLowerCase() ?? '';
      final code = (p['barcode'] as String?)?.toLowerCase() ?? '';
      final cat = (p['category'] as String?)?.toLowerCase() ?? '';
      return name.contains(q) || code.contains(q) || cat.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredProducts();

    return AppShell(
      title: 'Stock Count Audit',
      selectedIndex: 3,
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
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Physical Shelf Inventory Count Audit',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Audit and verify real items on shelves against the central system database to resolve shrinkage or surplus.',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            decoration: const InputDecoration(
                              hintText: 'Search products by name, barcode, or category...',
                              prefixIcon: Icon(Icons.search, color: Color(0xFF168B45)),
                            ),
                            onChanged: (v) => setState(() => _searchQuery = v.trim()),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final p = filtered[index];
                          final id = p['id'].toString();
                          final sysQty = (p['quantity'] as num?)?.toInt() ?? 0;
                          final ctrl = _controllers[id];
                          final unit = p['unit'] ?? 'units';

                          int countedQty = sysQty;
                          if (ctrl != null) {
                            countedQty = int.tryParse(ctrl.text.trim()) ?? sysQty;
                          }
                          final variance = countedQty - sysQty;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: LayoutBuilder(
                                builder: (context, cardConstraints) {
                                  final isMobile = cardConstraints.maxWidth < 620;

                                  if (isMobile) {
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 18,
                                              backgroundColor: const Color(0xFF168B45).withAlpha(20),
                                              child: const Icon(Icons.inventory_2, color: Color(0xFF168B45), size: 18),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    p['name'] ?? 'Item',
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  Text(
                                                    '${p['barcode']} • ${p['category']}',
                                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'System Stock: $sysQty $unit',
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF0F172A)),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextField(
                                                controller: ctrl,
                                                textAlign: TextAlign.center,
                                                keyboardType: TextInputType.number,
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                                decoration: InputDecoration(
                                                  labelText: 'Counted',
                                                  isDense: true,
                                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                                onChanged: (_) => setState(() {}),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: variance == 0
                                                    ? const Color(0xFF168B45).withAlpha(20)
                                                    : (variance < 0 ? const Color(0xFFEF4444).withAlpha(20) : const Color(0xFF0284C7).withAlpha(20)),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Column(
                                                children: [
                                                  const Text('Variance', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                                  Text(
                                                    variance > 0 ? '+$variance' : '$variance',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 13,
                                                      color: variance == 0
                                                          ? const Color(0xFF168B45)
                                                          : (variance < 0 ? const Color(0xFFEF4444) : const Color(0xFF0284C7)),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF168B45),
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                              onPressed: () => _syncPhysicalCount(p),
                                              child: const Text('Sync', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    );
                                  }

                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: const Color(0xFF168B45).withAlpha(20),
                                        child: const Icon(Icons.inventory_2, color: Color(0xFF168B45)),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        flex: 3,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p['name'] ?? 'Item',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Barcode: ${p['barcode']} • Cat: ${p['category']}',
                                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'System Count: $sysQty $unit',
                                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF0F172A)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          const Text('Counted', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                          const SizedBox(height: 4),
                                          SizedBox(
                                            width: 80,
                                            child: TextField(
                                              controller: ctrl,
                                              textAlign: TextAlign.center,
                                              keyboardType: TextInputType.number,
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                              decoration: InputDecoration(
                                                isDense: true,
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                              onChanged: (_) => setState(() {}),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          const Text('Variance', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: variance == 0
                                                  ? const Color(0xFF168B45).withAlpha(20)
                                                  : (variance < 0 ? const Color(0xFFEF4444).withAlpha(20) : const Color(0xFF0284C7).withAlpha(20)),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              variance > 0 ? '+$variance' : '$variance',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: variance == 0
                                                    ? const Color(0xFF168B45)
                                                    : (variance < 0 ? const Color(0xFFEF4444) : const Color(0xFF0284C7)),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 12),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF168B45),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        onPressed: () => _syncPhysicalCount(p),
                                        child: const Text('Sync', style: TextStyle(fontSize: 12)),
                                      ),
                                    ],
                                  );
                                },
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
