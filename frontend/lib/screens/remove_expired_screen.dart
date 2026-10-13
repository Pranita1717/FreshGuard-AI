import 'package:flutter/material.dart';
import '../services/api.dart';
import '../widgets/app_shell.dart';

class RemoveExpiredScreen extends StatefulWidget {
  const RemoveExpiredScreen({super.key});

  @override
  State<RemoveExpiredScreen> createState() => _RemoveExpiredScreenState();
}

class _RemoveExpiredScreenState extends State<RemoveExpiredScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _expiredProducts = [];

  @override
  void initState() {
    super.initState();
    _loadExpiredProducts();
  }

  Future<void> _loadExpiredProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await ApiService().getProducts();
      if (!mounted) return;
      setState(() {
        _expiredProducts = data.where((p) {
          if ((p['expiryStatus'] ?? 'SAFE') == 'REMOVED') return false;
          final status = (p['expiryStatus'] as String?)?.toUpperCase();
          final days = (p['daysUntilExpiry'] as num?)?.toInt();
          return status == 'EXPIRED' || (days != null && days < 0);
        }).toList();
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
        _errorMessage = 'Failed to load expired products: $e';
        _isLoading = false;
      });
    }
  }

  void _showDisposalDialog(Map<String, dynamic> product) {
    final qtyCtrl = TextEditingController(text: '${product['quantity'] ?? 1}');
    String disposalReason = 'Safe Bio-Waste Disposal';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.delete_forever, color: Color(0xFFEF4444)),
              SizedBox(width: 8),
              Text('Expired Stock Disposal'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Product: ${product['name']}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text('Expired on: ${product['expiryDate']}', style: const TextStyle(color: Color(0xFFEF4444))),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: disposalReason,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Disposal Protocol / Method'),
                items: const [
                  DropdownMenuItem(value: 'Safe Bio-Waste Disposal', child: Text('Safe Bio-Waste Disposal')),
                  DropdownMenuItem(value: 'Vendor Expiry Return / Claim', child: Text('Vendor Expiry Return / Claim')),
                  DropdownMenuItem(value: 'Spoilage / Damaged Dump', child: Text('Spoilage / Damaged Dump')),
                  DropdownMenuItem(value: 'Audit Write-Off', child: Text('Audit Write-Off')),
                ],
                onChanged: (v) => setDlgState(() => disposalReason = v ?? disposalReason),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Units to Dispose',
                  helperText: 'Available: ${product['quantity']} ${product['unit'] ?? "units"}',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
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
                  await ApiService().removeExpiredProduct(
                    product['id'],
                    qty,
                    disposalReason,
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Safely disposed $qty units of ${product['name']}! Audit log recorded.'),
                      backgroundColor: const Color(0xFF168B45),
                    ),
                  );
                  _loadExpiredProducts();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Disposal failed: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Confirm Disposal'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Remove Expired Stock',
      selectedIndex: 4,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Color(0xFF168B45)),
          tooltip: 'Refresh',
          onPressed: _loadExpiredProducts,
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
                      ElevatedButton(onPressed: _loadExpiredProducts, child: const Text('Retry')),
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
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.warning, color: Color(0xFFEF4444), size: 28),
                            SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Zero Customer Spoilage Policy',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF991B1B)),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Expired items must be de-listed and physically removed from shelves. Audit records are permanently recorded in the store audit ledger.',
                                    style: TextStyle(fontSize: 12, color: Color(0xFFB91C1C)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Identified Expired Products',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withAlpha(20),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_expiredProducts.length} items',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF4444), fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (_expiredProducts.isEmpty)
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
                                Icon(Icons.check_circle, color: Color(0xFF168B45), size: 54),
                                SizedBox(height: 14),
                                Text(
                                  'All Shelves Are Clean and Safe!',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'There are currently zero expired products in the store inventory.',
                                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _expiredProducts.length,
                          itemBuilder: (context, index) {
                            final p = _expiredProducts[index];
                            final days = (p['daysUntilExpiry'] as num?)?.toInt() ?? 0;
                            final qty = p['quantity'] ?? 0;
                            final unit = p['unit'] ?? 'units';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isWide = constraints.maxWidth >= 550;

                                    if (isWide) {
                                      return Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: const Color(0xFFEF4444).withAlpha(20),
                                            child: const Icon(Icons.cancel, color: Color(0xFFEF4444)),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  p['name'] ?? 'Product',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Barcode: ${p['barcode']} • Cat: ${p['category']}',
                                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                                ),
                                                const SizedBox(height: 4),
                                                Wrap(
                                                  spacing: 8,
                                                  children: [
                                                    Text(
                                                      'Expired: ${p['expiryDate']}',
                                                      style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600, fontSize: 12),
                                                    ),
                                                    Text(
                                                      '(${days.abs()} days overdue)',
                                                      style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                'On Shelf: $qty $unit',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                              ),
                                              const SizedBox(height: 8),
                                              ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFFEF4444),
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                                icon: const Icon(Icons.delete_outline, size: 16),
                                                label: const Text('Dispose', style: TextStyle(fontSize: 12)),
                                                onPressed: () => _showDisposalDialog(p),
                                              ),
                                            ],
                                          ),
                                        ],
                                      );
                                    }

                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: const Color(0xFFEF4444).withAlpha(20),
                                              child: const Icon(Icons.cancel, color: Color(0xFFEF4444)),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                p['name'] ?? 'Product',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEF4444).withAlpha(15),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                '$qty $unit',
                                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF4444), fontSize: 13),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Barcode: ${p['barcode']} • Cat: ${p['category']}',
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Expired: ${p['expiryDate']} (${days.abs()} days overdue)',
                                          style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600, fontSize: 12),
                                        ),
                                        const SizedBox(height: 12),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFFEF4444),
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                            icon: const Icon(Icons.delete_outline, size: 16),
                                            label: const Text('Execute Disposal Protocol', style: TextStyle(fontSize: 13)),
                                            onPressed: () => _showDisposalDialog(p),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
    );
  }
}
