import 'package:flutter/material.dart';
import '../services/api.dart';
import '../widgets/app_shell.dart';
import '../widgets/stat_card.dart';

class RestockingScreen extends StatefulWidget {
  const RestockingScreen({super.key});

  @override
  State<RestockingScreen> createState() => _RestockingScreenState();
}

class _RestockingScreenState extends State<RestockingScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _restockingItems = [];

  @override
  void initState() {
    super.initState();
    _loadRestocking();
  }

  Future<void> _loadRestocking() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await ApiService().getRestocking();
      if (!mounted) return;
      setState(() {
        _restockingItems = data;
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
        _errorMessage = 'Unable to load restocking information. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _showReceiveStockDialog(Map<String, dynamic> item) {
    final id = (item['productId'] ?? item['id'])?.toString() ?? '';
    final name = (item['productName'] ?? item['name'])?.toString() ?? 'Product';
    final suggested = (item['suggestedQuantity'] ?? item['suggestedRestock'] as num?)?.toInt() ?? 10;
    final current = (item['currentQuantity'] ?? item['currentStock'] as num?)?.toInt() ?? 0;
    final unit = item['unit']?.toString() ?? 'units';
    final qtyCtrl = TextEditingController(text: '$suggested');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Receive delivery?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Product: $name', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            Text('Current Stock: $current $unit', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
            const SizedBox(height: 4),
            Text('Suggested Quantity: $suggested $unit', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Received Quantity Units',
                hintText: 'Enter units received',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF168B45),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final qty = int.tryParse(qtyCtrl.text.trim());
              if (qty == null || qty <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid positive quantity')),
                );
                return;
              }
              Navigator.pop(ctx);
              try {
                await ApiService().updateInventory(
                  id,
                  'RECEIVE_DELIVERY',
                  qty,
                  'Received supplier delivery order for $name',
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Successfully received delivery of $qty $unit for $name!'),
                    backgroundColor: const Color(0xFF168B45),
                  ),
                );
                await _loadRestocking();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Unable to update inventory. Please try again.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Confirm Delivery'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalUnitsNeeded = _restockingItems.fold<int>(
      0,
      (sum, item) {
        final val = (item['suggestedQuantity'] ?? item['suggestedRestock']) as num?;
        return sum + (val?.toInt() ?? 0);
      },
    );

    return AppShell(
      title: 'Restocking Intelligence',
      selectedIndex: 7,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Color(0xFF168B45)),
          tooltip: 'Refresh',
          onPressed: _loadRestocking,
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
                      ElevatedButton(onPressed: _loadRestocking, child: const Text('Retry')),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calculate, color: Color(0xFF168B45), size: 28),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Deterministic Restocking Formula',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF065F46)),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Suggested Order = max(0, (Minimum Stock × 2) − Current Quantity). Triggered when stock falls below safety buffer.',
                                    style: TextStyle(fontSize: 12, color: Color(0xFF047857)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          int crossAxisCount = 3;
                          if (constraints.maxWidth < 650) {
                            crossAxisCount = 1;
                          } else if (constraints.maxWidth < 1050) {
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
                                title: 'SKUs Needing Reorder',
                                value: '${_restockingItems.length}',
                                subtitle: 'Below safety buffer',
                                icon: Icons.warning_amber_rounded,
                                color: const Color(0xFFD97706),
                              ),
                              StatCard(
                                title: 'Total Recommended Units',
                                value: '$totalUnitsNeeded',
                                subtitle: 'Aggregated purchase volume',
                                icon: Icons.local_shipping,
                                color: const Color(0xFF168B45),
                              ),
                              StatCard(
                                title: 'Order Status',
                                value: _restockingItems.isEmpty ? 'Optimal' : 'Action Needed',
                                subtitle: _restockingItems.isEmpty ? 'No stockouts detected' : 'Submit PO to distributors',
                                icon: Icons.check_circle_outline,
                                color: _restockingItems.isEmpty ? const Color(0xFF168B45) : const Color(0xFFEF4444),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recommended Purchase Orders',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          Text(
                            '${_restockingItems.length} items',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_restockingItems.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: const Center(
                            child: Column(
                              children: [
                                Icon(Icons.check_circle, color: Color(0xFF168B45), size: 52),
                                SizedBox(height: 14),
                                Text('Store Shelves Are Well-Stocked!',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                SizedBox(height: 4),
                                Text('All items have current quantity strictly greater than minimum stock buffers.',
                                    style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
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
                            itemCount: _restockingItems.length,
                            separatorBuilder: (_, _) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = _restockingItems[index];
                              final current = (item['currentQuantity'] ?? item['currentStock'] as num?)?.toInt() ?? 0;
                              final min = (item['minimumStock'] as num?)?.toInt() ?? 0;
                              final suggested = (item['suggestedQuantity'] ?? item['suggestedRestock'] as num?)?.toInt() ?? 0;
                              final unit = item['unit']?.toString() ?? 'units';
                              final name = (item['productName'] ?? item['name'])?.toString() ?? 'Item';
                              final category = item['category']?.toString() ?? 'General';
                              final barcode = item['barcode']?.toString() ?? '';

                              return LayoutBuilder(
                                builder: (context, cardConstraints) {
                                  final isCompact = cardConstraints.maxWidth < 620;

                                  if (isCompact) {
                                    return Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 20,
                                                backgroundColor: const Color(0xFFD97706).withAlpha(25),
                                                child: const Icon(Icons.inventory, color: Color(0xFFD97706), size: 20),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      name,
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    Text(
                                                      '$category • $barcode',
                                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF168B45).withAlpha(20),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  '+$suggested $unit',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                    color: Color(0xFF168B45),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Wrap(
                                            spacing: 12,
                                            runSpacing: 4,
                                            children: [
                                              Text(
                                                'Current: $current $unit',
                                                style: TextStyle(
                                                  color: current == 0 ? const Color(0xFFEF4444) : const Color(0xFFD97706),
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              Text(
                                                'Min Buffer: $min $unit',
                                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                              ),
                                            ],
                                          ),
                                          if (item['ruleReason'] != null) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              'Rule: ${item['ruleReason']}',
                                              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                            ),
                                          ],
                                          const SizedBox(height: 12),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF168B45),
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(vertical: 10),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                              icon: const Icon(Icons.add_shopping_cart, size: 16),
                                              label: const Text('Receive Delivery', style: TextStyle(fontWeight: FontWeight.bold)),
                                              onPressed: () => _showReceiveStockDialog(item),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        CircleAvatar(
                                          radius: 22,
                                          backgroundColor: const Color(0xFFD97706).withAlpha(25),
                                          child: const Icon(Icons.inventory, color: Color(0xFFD97706), size: 22),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Barcode: $barcode • Category: $category',
                                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Text(
                                                    'Current: $current $unit',
                                                    style: TextStyle(
                                                      color: current == 0 ? const Color(0xFFEF4444) : const Color(0xFFD97706),
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text('•', style: TextStyle(color: Colors.grey.shade400)),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Minimum Buffer: $min $unit',
                                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                                  ),
                                                ],
                                              ),
                                              if (item['ruleReason'] != null)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 2),
                                                  child: Text(
                                                    'Rule: ${item['ruleReason']}',
                                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF168B45).withAlpha(20),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '+$suggested $unit',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: Color(0xFF168B45),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF168B45),
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                              icon: const Icon(Icons.add_shopping_cart, size: 14),
                                              label: const Text('Receive Delivery', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                              onPressed: () => _showReceiveStockDialog(item),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
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
