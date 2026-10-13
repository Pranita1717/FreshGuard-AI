import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api.dart';
import '../services/session.dart';
import '../services/report_file_saver.dart';
import '../widgets/app_shell.dart';
import '../widgets/stat_card.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedType = 'SUMMARY';
  bool _isLoading = true;
  bool _isDownloadingPdf = false;
  String? _errorMessage;
  Map<String, dynamic> _reportData = {};

  final List<Map<String, String>> _reportTypes = [
    {'id': 'SUMMARY', 'label': 'Executive Summary', 'desc': 'Comprehensive store health & status distribution'},
    {'id': 'INVENTORY', 'label': 'Inventory Valuation', 'desc': 'Full catalog valuation and unit stock levels'},
    {'id': 'EXPIRY', 'label': 'Expiry Risk Audit', 'desc': 'Critical items nearing shelf life & expired items'},
    {'id': 'LOW_STOCK', 'label': 'Low Stock Audit', 'desc': 'Items fallen below configured safety buffers'},
  ];

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await ApiService().getReport(_selectedType);
      if (!mounted) return;
      setState(() {
        _reportData = data;
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
        _errorMessage = 'Failed to load report data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadPdf() async {
    setState(() => _isDownloadingPdf = true);
    final filename = 'freshguard_${_selectedType.toLowerCase()}_report.pdf';
    final url = ApiService().getReportPdfDownloadUrl(_selectedType);
    try {
      final token = Session().token;
      final response = await http.get(
        Uri.parse(url),
        headers: {if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token'},
      );
      if (response.statusCode != 200) {
        throw ApiException('Failed to generate PDF (HTTP ${response.statusCode})', response.statusCode);
      }
      final savedPath = await saveReportFile(response.bodyBytes, filename);
      if (!mounted) return;
      setState(() => _isDownloadingPdf = false);
      final message = savedPath == null
          ? 'PDF generated successfully, but your platform did not expose a file-save location.'
          : 'PDF downloaded successfully: $savedPath';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: const Color(0xFF168B45), duration: const Duration(seconds: 4)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDownloadingPdf = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF download error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildSummaryContent() {
    final total = _reportData['totalProducts'] ?? 0;
    final totalQty = _reportData['totalQuantity'] ?? 0;
    final expired = _reportData['expiredCount'] ?? 0;
    final critical = _reportData['criticalCount'] ?? 0;
    final nearExpiry = _reportData['nearExpiryCount'] ?? 0;
    final safe = _reportData['safeCount'] ?? 0;
    final lowStock = _reportData['lowStockCount'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = 4;
            if (constraints.maxWidth < 600) {
              crossAxisCount = 1;
            } else if (constraints.maxWidth < 1100) {
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
                  title: 'Total SKU Items',
                  value: '$total',
                  subtitle: '$totalQty physical units',
                  icon: Icons.inventory_2,
                  color: const Color(0xFF168B45),
                ),
                StatCard(
                  title: 'Expired Items',
                  value: '$expired',
                  subtitle: 'Bio-waste disposal',
                  icon: Icons.cancel,
                  color: const Color(0xFFEF4444),
                ),
                StatCard(
                  title: 'Critical Expiry (≤7d)',
                  value: '$critical',
                  subtitle: 'Triage front of shelf',
                  icon: Icons.priority_high,
                  color: const Color(0xFFDC2626),
                ),
                StatCard(
                  title: 'Near Expiry (8-30d)',
                  value: '$nearExpiry',
                  subtitle: 'Eligible for markdown',
                  icon: Icons.alarm,
                  color: const Color(0xFFD97706),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Safety Status Distribution',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 16),
              _buildMetricRow('Safe Products (>30 Days)', '$safe', const Color(0xFF168B45)),
              const Divider(height: 20),
              _buildMetricRow('Near Expiry (8 to 30 Days)', '$nearExpiry', const Color(0xFFD97706)),
              const Divider(height: 20),
              _buildMetricRow('Critical Expiry (≤ 7 Days)', '$critical', const Color(0xFFDC2626)),
              const Divider(height: 20),
              _buildMetricRow('Expired Shelf Stock', '$expired', const Color(0xFFEF4444)),
              const Divider(height: 20),
              _buildMetricRow('Low Stock Buffer Warnings', '$lowStock', const Color(0xFF0284C7)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Flexible(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
            ],
          ),
        ),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
      ],
    );
  }

  Widget _buildItemsListContent() {
    final items = (_reportData['items'] as List<dynamic>?) ?? [];
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Center(
          child: Text('No records matching this report criteria.', style: TextStyle(color: Color(0xFF64748B))),
        ),
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
        itemCount: items.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final p = items[index];
          final qty = p['quantity'] ?? 0;
          final price = (p['price'] as num?)?.toDouble() ?? 0.0;
          final totalValuation = qty * price;

          return ListTile(
            title: Text(p['name'] ?? 'Product', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              'Barcode: ${p['barcode']} • Expiry: ${p['expiryDate']} • Stock: $qty ${p['unit'] ?? "units"}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('₹${totalValuation.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('₹${price.toStringAsFixed(2)} each', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Reports & PDF Export',
      selectedIndex: 9,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Color(0xFF168B45)),
          tooltip: 'Refresh Report',
          onPressed: _loadReport,
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
                      ElevatedButton(onPressed: _loadReport, child: const Text('Retry')),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 600;

                          if (isWide) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _reportData['title'] ?? 'Store Inventory Report',
                                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                      ),
                                      const SizedBox(height: 4),
                                      Text('Generated: ${_reportData['generatedAt'] ?? ""}',
                                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                                    ],
                                  ),
                                ),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFDC2626),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  icon: _isDownloadingPdf
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        )
                                      : const Icon(Icons.picture_as_pdf, size: 18),
                                  label: Text(_isDownloadingPdf ? 'Generating...' : 'Download PDF Report'),
                                  onPressed: _isDownloadingPdf ? null : _downloadPdf,
                                ),
                              ],
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                _reportData['title'] ?? 'Store Inventory Report',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 4),
                              Text('Generated: ${_reportData['generatedAt'] ?? ""}',
                                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFDC2626),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: _isDownloadingPdf
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : const Icon(Icons.picture_as_pdf, size: 18),
                                label: Text(_isDownloadingPdf ? 'Generating...' : 'Download PDF Report'),
                                onPressed: _isDownloadingPdf ? null : _downloadPdf,
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _reportTypes.map((t) {
                            final isSelected = _selectedType == t['id'];
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(t['label']!),
                                selected: isSelected,
                                selectedColor: const Color(0xFF168B45),
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : const Color(0xFF334155),
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                onSelected: (val) {
                                  if (val && _selectedType != t['id']) {
                                    setState(() => _selectedType = t['id']!);
                                    _loadReport();
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_selectedType == 'SUMMARY')
                        _buildSummaryContent()
                      else
                        _buildItemsListContent(),
                    ],
                  ),
                ),
    );
  }
}
