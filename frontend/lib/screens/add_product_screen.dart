import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api.dart';
import '../services/session.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _barcodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();

  final _quantityController = TextEditingController();
  final _unitController = TextEditingController();
  final _minStockController = TextEditingController();
  final _priceController = TextEditingController();

  String? _selectedCategory;
  DateTime? _mfgDate;
  DateTime? _expiryDate;
  bool _isLoading = false;
  String? _errorMessage;
  bool _routeBarcodeApplied = false;

  final List<String> _categories = [
    'Dairy & Eggs',
    'Bakery',
    'Pantry & Grains',
    'Beverages',
    'Produce',
    'Snacks',
    'Canned Goods',
    'Frozen Foods',
  ];

  @override
  void initState() {
    super.initState();
    // Product values are intentionally blank until entered or scanned by the user.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // When opened from Scan Product's 'Add Product' action, carry the scanned
    // barcode into the read-only barcode field automatically. Other entry
    // points (such as Inventory > Add Product) remain blank until scanned.
    if (!_routeBarcodeApplied) {
      _routeBarcodeApplied = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map) {
        final barcode = (args['barcode'] ?? '').toString().trim();
        if (barcode.isNotEmpty) {
          _barcodeController.text = barcode;
        }
      }
    }
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _nameController.dispose();
    _brandController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _minStockController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    var handled = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Scan Product Barcode'),
        content: SizedBox(
          width: 360,
          height: 320,
          child: MobileScanner(
            onDetect: (capture) {
              if (handled) return;
              final value = capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
              if (value == null || value.trim().isEmpty) return;
              handled = true;
              _barcodeController.text = value.trim();
              Navigator.of(dialogContext).pop();
              if (mounted) setState(() => _errorMessage = null);
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel'))],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isExpiry) async {
    final initial = isExpiry ? (_expiryDate ?? DateTime.now().add(const Duration(days: 30))) : (_mfgDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF168B45),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isExpiry) {
          _expiryDate = picked;
        } else {
          _mfgDate = picked;
        }
      });
    }
  }

  String _calculateStatusPreview() {
    if (_expiryDate == null) return 'SAFE';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final exp = DateTime(_expiryDate!.year, _expiryDate!.month, _expiryDate!.day);
    final diff = exp.difference(today).inDays;

    if (diff < 0) return 'EXPIRED';
    if (diff <= 7) return 'CRITICAL';
    if (diff <= 30) return 'NEAR_EXPIRY';
    return 'SAFE';
  }

  String _calculatePriorityPreview(String status) {
    if (status == 'EXPIRED' || status == 'CRITICAL') return 'HIGH';
    if (status == 'NEAR_EXPIRY') return 'MEDIUM';
    return 'LOW';
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_barcodeController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Scan the product barcode before saving');
      return;
    }
    if (_selectedCategory == null) {
      setState(() => _errorMessage = 'Please select a product category');
      return;
    }
    if (_expiryDate == null) {
      setState(() => _errorMessage = 'Please select a valid expiry date');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final session = Session();
      final data = {
        'barcode': _barcodeController.text.trim(),
        'name': _nameController.text.trim(),
        'category': _selectedCategory!,
        'brand': _brandController.text.trim(),
        'quantity': int.parse(_quantityController.text.trim()),
        'unit': _unitController.text.trim(),
        'minimumStock': int.parse(_minStockController.text.trim()),
        'price': double.parse(_priceController.text.trim()),
        if (_mfgDate != null) 'manufacturingDate': DateFormat('yyyy-MM-dd').format(_mfgDate!),
        'expiryDate': DateFormat('yyyy-MM-dd').format(_expiryDate!),
        'storeName': session.storeName ?? 'Main Supermarket',
      };

      await ApiService().createProduct(data);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Product "${_nameController.text}" cataloged successfully!'),
          backgroundColor: const Color(0xFF168B45),
        ),
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Failed to create product: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusPreview = _calculateStatusPreview();
    final priorityPreview = _calculatePriorityPreview(statusPreview);

    Color statusColor = const Color(0xFF168B45);
    if (statusPreview == 'EXPIRED') statusColor = const Color(0xFFEF4444);
    if (statusPreview == 'CRITICAL') statusColor = const Color(0xFFDC2626);
    if (statusPreview == 'NEAR_EXPIRY') statusColor = const Color(0xFFD97706);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text('Add Product to Inventory', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Rule Preview Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Automatic Rule-Based Triage Preview',
                                style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: statusColor.withAlpha(20),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: statusColor.withAlpha(80)),
                                    ),
                                    child: Text(
                                      statusPreview,
                                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ),
                                  Text(
                                    'Shelf Priority: $priorityPreview',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.rule, color: statusColor, size: 28),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Product Form Content with Responsive Columns
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 700;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Product Details Card
                          Card(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Basic Product Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 16),
                                  if (isWide) ...[
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: _nameController,
                                            decoration: const InputDecoration(labelText: 'Product Name *', prefixIcon: Icon(Icons.shopping_bag_outlined)),
                                            validator: (val) => (val == null || val.trim().isEmpty) ? 'Product name is required' : null,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: TextFormField(controller: _barcodeController, readOnly: true, decoration: const InputDecoration(labelText: 'Barcode (scan required) *', prefixIcon: Icon(Icons.qr_code_scanner)), validator: (val) => (val == null || val.trim().isEmpty) ? 'Scan the barcode to continue' : null),
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton.filledTonal(icon: const Icon(Icons.camera_alt), tooltip: 'Scan barcode', onPressed: _scanBarcode),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: DropdownButtonFormField<String>(
                                            isExpanded: true,
                                            initialValue: _selectedCategory,
                                            decoration: const InputDecoration(labelText: 'Category *', prefixIcon: Icon(Icons.category_outlined)),
                                            validator: (val) => val == null ? 'Select a category' : null,
                                            items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                            onChanged: (val) {
                                              if (val != null) setState(() => _selectedCategory = val);
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: TextFormField(
                                            controller: _brandController,
                                            decoration: const InputDecoration(labelText: 'Brand / Manufacturer', prefixIcon: Icon(Icons.business_outlined)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ] else ...[
                                    TextFormField(
                                      controller: _nameController,
                                      decoration: const InputDecoration(labelText: 'Product Name *', prefixIcon: Icon(Icons.shopping_bag_outlined)),
                                      validator: (val) => (val == null || val.trim().isEmpty) ? 'Product name is required' : null,
                                    ),
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(controller: _barcodeController, readOnly: true, decoration: const InputDecoration(labelText: 'Barcode (scan required) *', prefixIcon: Icon(Icons.qr_code_scanner)), validator: (val) => (val == null || val.trim().isEmpty) ? 'Scan the barcode to continue' : null),
                                        ),
                                        const SizedBox(width: 8),
                                              IconButton.filledTonal(icon: const Icon(Icons.camera_alt), tooltip: 'Scan barcode', onPressed: _scanBarcode),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    DropdownButtonFormField<String>(
                                      isExpanded: true,
                                      initialValue: _selectedCategory,
                                      decoration: const InputDecoration(labelText: 'Category *', prefixIcon: Icon(Icons.category_outlined)),
                                      validator: (val) => val == null ? 'Select a category' : null,
                                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                      onChanged: (val) {
                                        if (val != null) setState(() => _selectedCategory = val);
                                      },
                                    ),
                                    const SizedBox(height: 14),
                                    TextFormField(
                                      controller: _brandController,
                                      decoration: const InputDecoration(labelText: 'Brand / Manufacturer', prefixIcon: Icon(Icons.business_outlined)),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Stock & Pricing Card
                          Card(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Inventory Stock & Pricing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 16),
                                  if (isWide) ...[
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: _quantityController,
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(labelText: 'Quantity in Stock *', prefixIcon: Icon(Icons.numbers)),
                                            validator: (val) {
                                              if (val == null || int.tryParse(val) == null || int.parse(val) < 0) {
                                                return 'Quantity must be >= 0';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: TextFormField(
                                            controller: _unitController,
                                            decoration: const InputDecoration(labelText: 'Unit (e.g. units, kg, packs) *', prefixIcon: Icon(Icons.straighten)),
                                            validator: (val) => (val == null || val.trim().isEmpty) ? 'Unit is required' : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: _priceController,
                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                            decoration: const InputDecoration(labelText: 'Unit Price (₹) *', prefixIcon: Icon(Icons.currency_rupee)),
                                            validator: (val) {
                                              if (val == null || double.tryParse(val) == null || double.parse(val) < 0) {
                                                return 'Valid price required';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: TextFormField(
                                            controller: _minStockController,
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(labelText: 'Min Stock Threshold *', prefixIcon: Icon(Icons.warning_amber_rounded)),
                                            validator: (val) {
                                              if (val == null || int.tryParse(val) == null || int.parse(val) < 0) {
                                                return 'Threshold must be >= 0';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ] else ...[
                                    TextFormField(
                                      controller: _quantityController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(labelText: 'Quantity in Stock *', prefixIcon: Icon(Icons.numbers)),
                                      validator: (val) {
                                        if (val == null || int.tryParse(val) == null || int.parse(val) < 0) {
                                          return 'Quantity must be >= 0';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),
                                    TextFormField(
                                      controller: _unitController,
                                      decoration: const InputDecoration(labelText: 'Unit (e.g. units, kg, packs) *', prefixIcon: Icon(Icons.straighten)),
                                            validator: (val) => (val == null || val.trim().isEmpty) ? 'Unit is required' : null,
                                    ),
                                    const SizedBox(height: 14),
                                    TextFormField(
                                      controller: _priceController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: const InputDecoration(labelText: 'Unit Price (₹) *', prefixIcon: Icon(Icons.currency_rupee)),
                                      validator: (val) {
                                        if (val == null || double.tryParse(val) == null || double.parse(val) < 0) {
                                          return 'Valid price required';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),
                                    TextFormField(
                                      controller: _minStockController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(labelText: 'Min Stock Threshold *', prefixIcon: Icon(Icons.warning_amber_rounded)),
                                      validator: (val) {
                                        if (val == null || int.tryParse(val) == null || int.parse(val) < 0) {
                                          return 'Threshold must be >= 0';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Expiry Dates Card
                          Card(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Manufacturing & Expiry Dates', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 16),
                                  if (isWide)
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ListTile(
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                              side: BorderSide(color: Colors.grey.shade300),
                                            ),
                                            leading: const Icon(Icons.calendar_today, color: Color(0xFF168B45)),
                                            title: const Text('Manufacturing Date', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                            subtitle: Text(
                                              _mfgDate != null ? DateFormat('dd/MM/yyyy').format(_mfgDate!) : 'Select Date',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                            onTap: () => _selectDate(context, false),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: ListTile(
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                              side: BorderSide(color: Colors.grey.shade300),
                                            ),
                                            leading: const Icon(Icons.event_available, color: Color(0xFFEF4444)),
                                            title: const Text('Expiry Date *', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                            subtitle: Text(
                                              _expiryDate != null ? DateFormat('dd/MM/yyyy').format(_expiryDate!) : 'Select Date',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                            onTap: () => _selectDate(context, true),
                                          ),
                                        ),
                                      ],
                                    )
                                  else ...[
                                    ListTile(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        side: BorderSide(color: Colors.grey.shade300),
                                      ),
                                      leading: const Icon(Icons.calendar_today, color: Color(0xFF168B45)),
                                      title: const Text('Manufacturing Date', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                      subtitle: Text(
                                        _mfgDate != null ? DateFormat('dd/MM/yyyy').format(_mfgDate!) : 'Select Date',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      onTap: () => _selectDate(context, false),
                                    ),
                                    const SizedBox(height: 12),
                                    ListTile(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        side: BorderSide(color: Colors.grey.shade300),
                                      ),
                                      leading: const Icon(Icons.event_available, color: Color(0xFFEF4444)),
                                      title: const Text('Expiry Date *', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                      subtitle: Text(
                                        _expiryDate != null ? DateFormat('dd/MM/yyyy').format(_expiryDate!) : 'Select Date',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      onTap: () => _selectDate(context, true),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Save and Cancel Action Buttons
                          if (isWide)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Cancel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 14),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                                    backgroundColor: const Color(0xFF168B45),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: _isLoading ? null : _handleSubmit,
                                  icon: _isLoading
                                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Icon(Icons.save),
                                  label: Text(_isLoading ? 'Saving...' : 'Save Product', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            )
                          else ...[
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: const Color(0xFF168B45),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _isLoading ? null : _handleSubmit,
                              icon: _isLoading
                                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.save),
                              label: Text(_isLoading ? 'Saving...' : 'Save Product', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
