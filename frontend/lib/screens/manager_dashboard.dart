import 'package:flutter/material.dart';
import '../services/api.dart';
import '../services/session.dart';
import '../widgets/app_shell.dart';
import '../widgets/stat_card.dart';

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _products = [];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await ApiService().get('/products');
      if (!mounted) return;
      setState(() {
        _products = data as List<dynamic>;
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
        _errorMessage = 'Failed to load store inventory: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = Session();

    final totalProducts = _products.length;
    final totalQty = _products.fold<int>(0, (sum, item) => sum + ((item['quantity'] as num?)?.toInt() ?? 0));
    final expiredCount = _products.where((p) => p['expiryStatus'] == 'EXPIRED').length;
    final nearExpiryCount = _products.where((p) => p['expiryStatus'] == 'NEAR_EXPIRY' || p['expiryStatus'] == 'CRITICAL').length;
    final safeCount = _products.where((p) => p['expiryStatus'] == 'SAFE' || p['expiryStatus'] == null).length;
    final lowStockCount = _products.where((p) {
      final qty = (p['quantity'] as num?)?.toInt() ?? 0;
      final min = (p['minimumStock'] as num?)?.toInt() ?? 0;
      return qty <= min;
    }).length;

    final cards = [
      StatCard(
        title: 'Total Products',
        value: '$totalProducts',
        subtitle: '$totalQty units in stock',
        icon: Icons.inventory_2,
        color: const Color(0xFF168B45),
      ),
      StatCard(
        title: 'Safe Products',
        value: '$safeCount',
        subtitle: 'Normal shelf life',
        icon: Icons.verified_user,
        color: const Color(0xFF10B981),
      ),
      StatCard(
        title: 'Near Expiry',
        value: '$nearExpiryCount',
        subtitle: 'Requires priority sale',
        icon: Icons.alarm,
        color: const Color(0xFFD97706),
      ),
      StatCard(
        title: 'Expired Products',
        value: '$expiredCount',
        subtitle: 'Immediate disposal',
        icon: Icons.dangerous,
        color: const Color(0xFFEF4444),
      ),
      StatCard(
        title: 'Low Stock Items',
        value: '$lowStockCount',
        subtitle: 'Below threshold',
        icon: Icons.inventory,
        color: const Color(0xFF0284C7),
      ),
    ];

    return AppShell(
      title: 'Store Manager Portal',
      selectedIndex: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Color(0xFF168B45)),
          tooltip: 'Refresh Inventory',
          onPressed: _fetchProducts,
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
                      ElevatedButton(onPressed: _fetchProducts, child: const Text('Retry')),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Store Overview: ${session.storeName ?? "FreshGuard Supermarket #101"}',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Manager: ${session.name ?? "Store Manager"} • Operational Console',
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          int crossAxisCount = 5;
                          if (constraints.maxWidth < 600) {
                            crossAxisCount = 1;
                          } else if (constraints.maxWidth < 950) {
                            crossAxisCount = 2;
                          } else if (constraints.maxWidth < 1300) {
                            crossAxisCount = 3;
                          }
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              mainAxisExtent: 140,
                            ),
                            itemCount: cards.length,
                            itemBuilder: (context, index) => cards[index],
                          );
                        },
                      ),
                      const SizedBox(height: 28),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final itemCount = Text(
                            '${_products.length} Items Listed',
                            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                          );
                          const heading = Text(
                            'Current Inventory Stock Status',
                            softWrap: true,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          );
                          if (constraints.maxWidth < 520) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [heading, const SizedBox(height: 4), itemCount],
                            );
                          }
                          return Row(
                            children: [Expanded(child: heading), const SizedBox(width: 12), itemCount],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      if (_products.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                const Text('No products currently registered in this store.',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                                const SizedBox(height: 6),
                                const Text('Add products via the Inventory page or Barcode Scanner to begin tracking.',
                                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add New Product'),
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF168B45), foregroundColor: Colors.white),
                                  onPressed: () => Navigator.pushReplacementNamed(context, '/manager/add-product'),
                                ),
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
                            itemCount: _products.length,
                            separatorBuilder: (_, _) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final p = _products[index];
                              final status = p['expiryStatus'] ?? 'SAFE';
                              Color statusColor = const Color(0xFF168B45);
                              if (status == 'EXPIRED') statusColor = const Color(0xFFEF4444);
                              if (status == 'CRITICAL') statusColor = const Color(0xFFDC2626);
                              if (status == 'NEAR_EXPIRY') statusColor = const Color(0xFFD97706);

                              final unit = p['unit'] ?? 'units';

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: statusColor.withAlpha(20),
                                  child: Icon(Icons.shopping_bag_outlined, color: statusColor),
                                ),
                                title: Text(p['name'] ?? 'Item', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                  'Barcode: ${p['barcode']} • Cat: ${p['category']} • Expiry: ${p['expiryDate']}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${p['quantity']} $unit',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: statusColor.withAlpha(20),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
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
