import 'package:flutter/material.dart';
import '../services/api.dart';
import '../widgets/app_shell.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _products = [];
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedStatus = 'All';

  final List<String> _categories = [
    'All',
    'Dairy & Eggs',
    'Bakery',
    'Pantry & Grains',
    'Beverages',
    'Produce',
    'Snacks',
    'Canned Goods',
  ];

  final List<String> _statuses = [
    'All',
    'SAFE',
    'NEAR_EXPIRY',
    'CRITICAL',
    'EXPIRED',
    'REMOVED',
  ];

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
        _errorMessage = 'Failed to load inventory: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteProduct(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to permanently remove "$name" from catalog?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiService().deleteProduct(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Product "$name" removed successfully'), backgroundColor: const Color(0xFF168B45)),
      );
      _fetchProducts();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting product: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _quickAdjustQuantity(String id, String name, int currentQty, int change) async {
    final newQty = currentQty + change;
    if (newQty < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stock quantity cannot be negative'), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      final action = change > 0 ? 'INCREASE' : 'DECREASE';
      await ApiService().updateInventory(id, action, change.abs(), 'Quick adjustment from catalog table');
      _fetchProducts();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stock adjustment failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  List<dynamic> get _filteredProducts {
    return _products.where((p) {
      final name = (p['name'] ?? '').toString().toLowerCase();
      final barcode = (p['barcode'] ?? '').toString().toLowerCase();
      final brand = (p['brand'] ?? '').toString().toLowerCase();
      final category = (p['category'] ?? '').toString();
      final status = (p['expiryStatus'] ?? '').toString();

      final matchesSearch = _searchQuery.isEmpty ||
          name.contains(_searchQuery.toLowerCase()) ||
          barcode.contains(_searchQuery.toLowerCase()) ||
          brand.contains(_searchQuery.toLowerCase());

      final matchesCategory = _selectedCategory == 'All' || category == _selectedCategory;
      final matchesStatus = _selectedStatus == 'All' || status == _selectedStatus;

      return matchesSearch && matchesCategory && matchesStatus;
    }).toList();
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'EXPIRED':
        return const Color(0xFFEF4444);
      case 'CRITICAL':
        return const Color(0xFFDC2626);
      case 'NEAR_EXPIRY':
        return const Color(0xFFD97706);
      case 'REMOVED':
        return const Color(0xFF64748B);
      default:
        return const Color(0xFF168B45);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredProducts;

    return AppShell(
      title: 'Store Inventory Catalog',
      selectedIndex: 2,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF168B45),
        foregroundColor: Colors.white,
        onPressed: () async {
          final added = await Navigator.of(context).pushNamed('/manager/add-product');
          if (added == true) _fetchProducts();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
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
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
                      _buildFilterBar(),
                      const SizedBox(height: 16),
                      _buildCategoryChips(),
                      const SizedBox(height: 16),
                      _buildStatusChips(),
                      const SizedBox(height: 24),
                      if (filtered.isEmpty)
                        _buildEmptyState()
                      else
                        _buildProductTable(filtered),
                    ],
                  ),
                ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by product name, barcode, or brand...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim();
                });
              },
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '${_filteredProducts.length} items',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((cat) {
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(cat),
              selected: isSelected,
              selectedColor: const Color(0xFF168B45).withAlpha(40),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF168B45) : const Color(0xFF334155),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              onSelected: (_) {
                setState(() {
                  _selectedCategory = cat;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _statuses.map((st) {
          final isSelected = _selectedStatus == st;
          final color = _getStatusColor(st);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(st),
              selected: isSelected,
              selectedColor: color.withAlpha(40),
              labelStyle: TextStyle(
                color: isSelected ? color : const Color(0xFF334155),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              onSelected: (_) {
                setState(() {
                  _selectedStatus = st;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Color(0xFF94A3B8)),
          SizedBox(height: 16),
          Text(
            'No matching products found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your search query or filters.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildProductTable(List<dynamic> products) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 750;

        if (isMobile) {
          return Column(
            children: products.map((p) => _buildProductCard(p)).toList(),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: products.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final p = products[index];
              final id = p['id'] ?? '';
              final name = p['name'] ?? 'Product';
              final barcode = p['barcode'] ?? 'N/A';
              final category = p['category'] ?? 'General';
              final brand = p['brand'] ?? '';
              final qty = (p['quantity'] as num?)?.toInt() ?? 0;
              final minStock = (p['minimumStock'] as num?)?.toInt() ?? 0;
              final price = (p['price'] as num?)?.toDouble() ?? 0.0;
              final expiryDate = p['expiryDate'] ?? 'N/A';
              final status = p['expiryStatus'] ?? 'SAFE';
              final priority = p['shelfPriority'] ?? 'LOW';
              final statusColor = _getStatusColor(status);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: statusColor.withAlpha(25),
                      child: Icon(Icons.shopping_basket_outlined, color: statusColor, size: 22),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text(
                            'Barcode: $barcode • Category: $category ${brand.isNotEmpty ? "• $brand" : ""}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Expiry: $expiryDate • Shelf Priority: $priority',
                            style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '₹${price.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: statusColor.withAlpha(20),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                                ),
                              ),
                              if (qty <= minStock && status != 'REMOVED') ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444).withAlpha(20),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'LOW',
                                    style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 10),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFEF4444), size: 20),
                          tooltip: 'Decrease Stock',
                          onPressed: () => _quickAdjustQuantity(id, name, qty, -1),
                        ),
                        Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Color(0xFF168B45), size: 20),
                          tooltip: 'Increase Stock',
                          onPressed: () => _quickAdjustQuantity(id, name, qty, 1),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Color(0xFF0284C7), size: 20),
                          tooltip: 'Edit Details',
                          onPressed: () async {
                            final edited = await Navigator.of(context).pushNamed(
                              '/manager/edit-product',
                              arguments: p,
                            );
                            if (edited == true) _fetchProducts();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                          tooltip: 'Delete Product',
                          onPressed: () => _deleteProduct(id, name),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProductCard(dynamic p) {
    final id = p['id'] ?? '';
    final name = p['name'] ?? 'Product';
    final barcode = p['barcode'] ?? 'N/A';
    final category = p['category'] ?? 'General';
    final brand = p['brand'] ?? '';
    final qty = (p['quantity'] as num?)?.toInt() ?? 0;
    final minStock = (p['minimumStock'] as num?)?.toInt() ?? 0;
    final price = (p['price'] as num?)?.toDouble() ?? 0.0;
    final expiryDate = p['expiryDate'] ?? 'N/A';
    final status = p['expiryStatus'] ?? 'SAFE';
    final statusColor = _getStatusColor(status);
    final isLowStock = qty <= minStock && status != 'REMOVED';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: statusColor.withAlpha(25),
                child: Icon(Icons.shopping_basket_outlined, color: statusColor, size: 20),
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
                    const SizedBox(height: 2),
                    Text(
                      '$category ${brand.isNotEmpty ? "• $brand" : ""} • $barcode',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                '₹${price.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF64748B).withAlpha(15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Exp: $expiryDate',
                  style: const TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.w500, fontSize: 11),
                ),
              ),
              if (isLowStock)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'LOW STOCK',
                    style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFEF4444), size: 20),
                    tooltip: 'Decrease Stock',
                    onPressed: () => _quickAdjustQuantity(id, name, qty, -1),
                  ),
                  Text('$qty in stock', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Color(0xFF168B45), size: 20),
                    tooltip: 'Increase Stock',
                    onPressed: () => _quickAdjustQuantity(id, name, qty, 1),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Color(0xFF0284C7), size: 20),
                    tooltip: 'Edit Details',
                    onPressed: () async {
                      final edited = await Navigator.of(context).pushNamed(
                        '/manager/edit-product',
                        arguments: p,
                      );
                      if (edited == true) _fetchProducts();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                    tooltip: 'Delete Product',
                    onPressed: () => _deleteProduct(id, name),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
