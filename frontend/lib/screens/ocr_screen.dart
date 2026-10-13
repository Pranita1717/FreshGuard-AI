import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api.dart';
import '../services/ocr_bridge.dart';
import '../widgets/app_shell.dart';

class OcrScreen extends StatefulWidget {
  const OcrScreen({super.key});

  @override
  State<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> {
  final _picker = ImagePicker();
  final _verifiedDateController = TextEditingController();

  bool _isInitDone = false;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  Uint8List? _selectedImageBytes;
  String? _selectedImageName;

  Map<String, dynamic>? _ocrResult;
  String? _rawOcrText;
  double? _confidence;

  List<dynamic> _products = [];
  Map<String, dynamic>? _targetProduct;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitDone) {
      _isInitDone = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        setState(() {
          _targetProduct = args;
        });
      }
    }
  }

  @override
  void dispose() {
    _verifiedDateController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    try {
      final prods = await ApiService().getProducts();
      if (!mounted) return;
      setState(() {
        _products = prods.where((p) => (p['expiryStatus'] ?? 'SAFE') != 'REMOVED').toList();
        if (_targetProduct == null && _products.isNotEmpty) {
          _targetProduct = _products.first;
        }
      });
    } catch (_) {}
  }

  Future<void> _captureOrPickImage(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(source: source);
      if (photo == null) return;

      final bytes = await photo.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
        _selectedImageName = photo.name;
        _ocrResult = null;
        _rawOcrText = null;
        _confidence = null;
        _errorMessage = null;
      });

      await _processImageOcr(bytes, photo.name, filePath: photo.path);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not access camera or gallery: $e';
      });
    }
  }

  Future<void> _processImageOcr(Uint8List bytes, String filename, {String? filePath}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _ocrResult = null;
    });

    try {
      String? clientExtractedText;
      double? clientConfidence;

      // 1. Try real in-browser WebAssembly OCR if running on Web (Chrome)
      try {
        final webOcrRes = await executeClientOcr(bytes, filePath: filePath);
        if (webOcrRes != null && webOcrRes['text'] != null) {
          clientExtractedText = webOcrRes['text']?.toString().trim();
          clientConfidence = (webOcrRes['confidence'] as num?)?.toDouble();
        }
      } catch (_) {}

      // 2. Process through Spring Boot backend OCR endpoint
      final result = await ApiService().extractOcr(
        text: (clientExtractedText != null && clientExtractedText.isNotEmpty) ? clientExtractedText : null,
        imageBytes: bytes,
        filename: filename,
      );

      if (!mounted) return;

      final detectedDate = result['extractedDate']?.toString();
      final rawText = (clientExtractedText != null && clientExtractedText.isNotEmpty)
          ? clientExtractedText
          : (result['rawText']?.toString() ?? '');
      final confidence = clientConfidence ?? (result['confidence'] as num?)?.toDouble();

      setState(() {
        _ocrResult = result;
        _rawOcrText = rawText;
        _confidence = confidence;
        _isLoading = false;

        if (detectedDate != null && detectedDate.isNotEmpty) {
          _verifiedDateController.text = detectedDate;
        } else {
          _errorMessage = 'No expiry date was detected on the label. Please enter the date manually.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not read the product label. Try a clearer image or enter the date manually.';
      });
    }
  }

  Future<void> _pickDate() async {
    DateTime initial = DateTime.now().add(const Duration(days: 30));
    final currentText = _verifiedDateController.text.trim();
    if (currentText.isNotEmpty) {
      final parsed = DateTime.tryParse(currentText);
      if (parsed != null) initial = parsed;
    }

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
      final iso = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      setState(() {
        _verifiedDateController.text = iso;
      });
    }
  }

  Future<void> _confirmAndSave() async {
    if (_targetProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or scan a target product first.')),
      );
      return;
    }

    final verifiedDate = _verifiedDateController.text.trim();
    if (verifiedDate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter or confirm a valid expiry date.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      String isoDate = verifiedDate;
      if (verifiedDate.contains('/')) {
        final parts = verifiedDate.split('/');
        if (parts.length == 3) {
          isoDate = '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
        } else if (parts.length == 2) {
          isoDate = '${parts[1]}-${parts[0].padLeft(2, '0')}-28';
        }
      } else if (verifiedDate.contains('-')) {
        final parts = verifiedDate.split('-');
        if (parts.length == 3 && parts[0].length <= 2) {
          isoDate = '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
        }
      }

      final prodId = _targetProduct!['id'] ?? _targetProduct!['productId'];
      final updated = await ApiService().updateProductExpiry(
        prodId.toString(),
        isoDate,
        ocrText: _rawOcrText,
      );

      if (!mounted) return;
      setState(() {
        _targetProduct = updated;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Expiry date for "${_targetProduct!['name']}" verified & updated in database ($isoDate)!'),
          backgroundColor: const Color(0xFF168B45),
        ),
      );
      _fetchProducts();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update product: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _retakeImage() {
    setState(() {
      _selectedImageBytes = null;
      _selectedImageName = null;
      _ocrResult = null;
      _rawOcrText = null;
      _confidence = null;
      _errorMessage = null;
      _verifiedDateController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'OCR Expiry Detection',
      selectedIndex: 4,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 780),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildProductIdentificationCard(),
                const SizedBox(height: 20),
                _buildImageCaptureCard(),
                const SizedBox(height: 20),
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        children: [
                          CircularProgressIndicator(color: Color(0xFF168B45)),
                          SizedBox(height: 14),
                          Text(
                            'Processing packaging label with OCR engine...',
                            style: TextStyle(color: Color(0xFF475569), fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_ocrResult != null || _rawOcrText != null)
                  _buildVerificationCard()
                else if (_errorMessage != null)
                  _buildErrorCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.document_scanner, color: Color(0xFF8B5CF6), size: 30),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Optical Expiry Date Detection',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                SizedBox(height: 4),
                Text(
                  'Capture product packaging photo to automatically detect printed expiry dates with mandatory staff verification.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductIdentificationCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 430;
              final scanButton = TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed('/manager/barcode');
                },
                icon: const Icon(Icons.qr_code_scanner, size: 16, color: Color(0xFF168B45)),
                label: const Text(
                  'Scan Barcode First',
                  style: TextStyle(color: Color(0xFF168B45), fontSize: 12),
                ),
              );
              final heading = const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_2_outlined, color: Color(0xFF168B45), size: 20),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Target Inventory Product',
                      softWrap: true,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                    ),
                  ),
                ],
              );
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [heading, Align(alignment: Alignment.centerLeft, child: scanButton)],
                );
              }
              return Row(
                children: [Expanded(child: heading), scanButton],
              );
            },
          ),
          const SizedBox(height: 10),
          if (_targetProduct != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _targetProduct!['name'] ?? 'Product',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'SKU: ${_targetProduct!['barcode']} • Current Expiry: ${_targetProduct!['expiryDate'] ?? 'Not set'}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF168B45).withAlpha(20),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Stock: ${_targetProduct!['quantity'] ?? 0}',
                      style: const TextStyle(color: Color(0xFF168B45), fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (_products.isNotEmpty) ...[
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _targetProduct != null ? (_targetProduct!['id'] ?? _targetProduct!['productId'])?.toString() : null,
              decoration: const InputDecoration(
                labelText: 'Change Target Product',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(),
              ),
              items: _products.map((p) {
                final id = (p['id'] ?? p['productId']).toString();
                return DropdownMenuItem<String>(
                  value: id,
                  child: Text('${p['name']} (${p['barcode']})', overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _targetProduct = _products.firstWhere(
                      (p) => (p['id'] ?? p['productId']).toString() == val,
                      orElse: () => _products.first,
                    );
                  });
                }
              },
            ),
          ] else
            const Text(
              'No products in catalog. Please add products or scan a barcode first.',
              style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
            ),
        ],
      ),
    );
  }

  Widget _buildImageCaptureCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Acquire Product Label Image',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Capture a clear photo of the packaging expiry label or upload an existing photo.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          if (_selectedImageBytes != null) ...[
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 220),
                  color: const Color(0xFF0F172A),
                  child: Image.memory(_selectedImageBytes!, fit: BoxFit.contain),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                _selectedImageName ?? 'Captured Packaging Label',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 14),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 460;
              final buttons = [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF168B45),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _captureOrPickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Capture Image'),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _captureOrPickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library, color: Color(0xFF168B45)),
                  label: const Text('Choose From Gallery'),
                ),
                if (kIsWeb)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _captureOrPickImage(ImageSource.gallery),
                    icon: const Icon(Icons.upload_file, color: Color(0xFF168B45)),
                    label: const Text('Upload Product Image'),
                  ),
              ];

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: buttons.map((b) => Padding(padding: const EdgeInsets.only(bottom: 8), child: b)).toList(),
                );
              }

              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: buttons,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationCard() {
    final rawText = _rawOcrText ?? '';
    final detectedDate = _verifiedDateController.text.trim();
    final confidencePct = _confidence != null ? (_confidence! * 100).toStringAsFixed(0) : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF168B45), size: 22),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'OCR Detection Result',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF168B45)),
                ),
              ),
              if (confidencePct != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFF168B45), borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    'Confidence: $confidencePct%',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (rawText.isNotEmpty) ...[
            const Text('Detected Text on Label:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(10),
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
              child: Text(
                rawText,
                style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            'Detected Expiry Date: ${detectedDate.isNotEmpty ? detectedDate : "Not found"}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Color(0xFFD97706)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mandatory staff verification: Verify or adjust the date below before updating the catalog.',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFD97706)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 24),
          const Text('Staff Verified Expiry Date:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _verifiedDateController,
                  decoration: const InputDecoration(
                    labelText: 'Verified Date (YYYY-MM-DD or DD/MM/YYYY)',
                    prefixIcon: Icon(Icons.event),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                icon: const Icon(Icons.calendar_month),
                tooltip: 'Select date from calendar',
                style: IconButton.styleFrom(backgroundColor: const Color(0xFF168B45)),
                onPressed: _pickDate,
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 450;
              final buttons = [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF168B45),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _isSaving ? null : _confirmAndSave,
                  icon: _isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Saving to Database...' : 'Confirm & Save Expiry Date'),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _retakeImage,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retake Image'),
                ),
              ];

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    buttons[0],
                    const SizedBox(height: 10),
                    buttons[1],
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: buttons[0]),
                  const SizedBox(width: 12),
                  Expanded(child: buttons[1]),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: Color(0xFF991B1B), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Color(0xFF991B1B), fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'You can still enter the printed expiry date manually below:',
            style: TextStyle(fontSize: 12, color: Color(0xFF7F1D1D)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _verifiedDateController,
                  decoration: const InputDecoration(
                    labelText: 'Manual Expiry Date (YYYY-MM-DD)',
                    prefixIcon: Icon(Icons.event),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                icon: const Icon(Icons.calendar_month),
                style: IconButton.styleFrom(backgroundColor: const Color(0xFF168B45)),
                onPressed: _pickDate,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF168B45),
              foregroundColor: Colors.white,
            ),
            onPressed: _isSaving ? null : _confirmAndSave,
            icon: const Icon(Icons.check),
            label: const Text('Save Manual Date'),
          ),
        ],
      ),
    );
  }
}
