import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api.dart';
import '../widgets/app_shell.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> with WidgetsBindingObserver {
  final _barcodeController = TextEditingController();
  final _picker = ImagePicker();

  MobileScannerController? _scannerController;
  bool _isCameraActive = true;
  bool _isTorchOn = false;
  bool _hasPermissionError = false;

  bool _isLoading = false;
  bool _isProcessingScan = false;
  String? _detectedBarcode;
  String? _errorMessage;
  Map<String, dynamic>? _foundProduct;

  bool get _isTest => const bool.fromEnvironment('FLUTTER_TEST', defaultValue: false);

  bool get _isDesktop {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  bool get _isCameraSupported {
    if (_isTest) return false;
    if (_isDesktop) return false;
    return true; // Android, iOS, and Web supported
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_isCameraSupported) {
      _initScanner();
    } else {
      _isCameraActive = false;
    }
  }

  void _initScanner() {
    _hasPermissionError = false;
    _scannerController?.dispose();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController?.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isCameraSupported || _scannerController == null) return;
    if (state == AppLifecycleState.resumed && _isCameraActive) {
      _scannerController?.start();
    } else if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _scannerController?.stop();
    }
  }

  Future<void> _handleBarcodeDetected(BarcodeCapture capture) async {
    if (_isProcessingScan) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawVal = barcodes.first.rawValue;
    if (rawVal == null || rawVal.trim().isEmpty) return;

    final code = rawVal.trim();
    setState(() {
      _isProcessingScan = true;
      _detectedBarcode = code;
      _barcodeController.text = code;
    });

    await _searchBarcode(code);
  }

  Future<void> _searchBarcode(String barcode) async {
    final code = barcode.trim();
    if (code.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _foundProduct = null;
    });

    try {
      final product = await ApiService().lookupBarcode(code);
      if (!mounted) return;
      setState(() {
        _foundProduct = product;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.statusCode == 404
            ? 'Product not found. The barcode "$code" is not in the store catalog.'
            : e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Scan lookup error: $e';
        _isLoading = false;
      });
    } finally {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) setState(() => _isProcessingScan = false);
        });
      }
    }
  }

  Future<void> _pickImageAndScan() async {
    try {
      final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;

      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _foundProduct = null;
      });

      if (_isCameraSupported && _scannerController != null) {
        final capture = await _scannerController!.analyzeImage(file.path);
        if (capture != null && capture.barcodes.isNotEmpty) {
          final code = capture.barcodes.first.rawValue;
          if (code != null && code.isNotEmpty) {
            setState(() {
              _detectedBarcode = code;
              _barcodeController.text = code;
            });
            await _searchBarcode(code);
            return;
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'No barcode detected in the selected image. Please try another image or enter the barcode manually.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to read image: $e';
      });
    }
  }

  Future<void> _updateQuantity(int change) async {
    if (_foundProduct == null) return;
    final currentQty = (_foundProduct!['quantity'] as num?)?.toInt() ?? 0;
    final newQty = currentQty + change;
    if (newQty < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantity cannot be negative'), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      final action = change > 0 ? 'INCREASE' : 'DECREASE';
      final updated = await ApiService().updateInventory(
        _foundProduct!['id'] ?? _foundProduct!['productId'],
        action,
        change.abs(),
        'Barcode scanner stock update',
      );
      if (!mounted) return;
      setState(() {
        _foundProduct = updated;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stock updated to ${updated['quantity']} units!'),
          backgroundColor: const Color(0xFF168B45),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update stock: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _resetScanner() {
    setState(() {
      _foundProduct = null;
      _errorMessage = null;
      _detectedBarcode = null;
      _isProcessingScan = false;
      _barcodeController.clear();
      _isCameraActive = true;
    });
    if (_isCameraSupported) {
      _initScanner();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Scan Product',
      selectedIndex: 3,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildCameraScannerCard(),
                const SizedBox(height: 16),
                _buildActionToolbar(),
                const SizedBox(height: 20),
                _buildManualInputCard(),
                const SizedBox(height: 20),
                if (_detectedBarcode != null && _detectedBarcode!.isNotEmpty) ...[
                  _buildDetectedBarcodeBanner(),
                  const SizedBox(height: 16),
                ],
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(color: Color(0xFF168B45)),
                    ),
                  )
                else if (_foundProduct != null)
                  _buildProductResultCard()
                else if (_errorMessage != null)
                  _buildNotFoundCard(),
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
              color: const Color(0xFF168B45).withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.qr_code_scanner, color: Color(0xFF168B45), size: 30),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scan Product',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                SizedBox(height: 4),
                Text(
                  'Scan a product barcode to view or update inventory.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraScannerCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 280,
              width: double.infinity,
              color: const Color(0xFF0F172A),
              child: _buildCameraContent(),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Align the barcode inside the frame.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraContent() {
    if (_isDesktop) {
      return _buildCameraFallbackView(
        icon: Icons.computer,
        title: 'Camera scanning is unavailable on this platform.',
        subtitle: 'Desktop environments do not support direct camera scanning. Use manual barcode entry or image upload below.',
      );
    }

    if (_hasPermissionError) {
      return _buildCameraFallbackView(
        icon: Icons.videocam_off,
        title: 'Camera permission is required to scan barcodes.',
        subtitle: 'Please grant camera access in browser or device settings to scan products.',
        actionLabel: 'Try Again',
        onAction: () {
          setState(() {
            _hasPermissionError = false;
            _initScanner();
          });
        },
      );
    }

    if (!_isCameraActive) {
      return _buildCameraFallbackView(
        icon: Icons.videocam_outlined,
        title: 'Camera scanner is currently paused.',
        subtitle: 'Tap the button below to resume camera barcode scanning.',
        actionLabel: 'Start Camera',
        onAction: () {
          setState(() {
            _isCameraActive = true;
            _initScanner();
          });
        },
      );
    }

    if (_isTest || _scannerController == null) {
      return _buildScannerOverlay();
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        MobileScanner(
          controller: _scannerController!,
          onDetect: _handleBarcodeDetected,
          errorBuilder: (context, error) {
            final isPermDenied = error.errorCode == MobileScannerErrorCode.permissionDenied;
            return _buildCameraFallbackView(
              icon: isPermDenied ? Icons.no_photography : Icons.videocam_off,
              title: isPermDenied
                  ? 'Camera permission is required to scan barcodes.'
                  : (kIsWeb ? 'Camera scanning is unavailable on this browser.' : 'Camera initialization error.'),
              subtitle: error.errorDetails?.message ?? 'Please check permissions or use manual entry.',
              actionLabel: isPermDenied ? 'Try Again' : null,
              onAction: isPermDenied ? () => setState(() => _initScanner()) : null,
            );
          },
        ),
        _buildScannerOverlay(),
        Positioned(
          top: 10,
          right: 10,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton.filledTonal(
                icon: Icon(_isTorchOn ? Icons.flash_on : Icons.flash_off, size: 20),
                tooltip: 'Toggle Flashlight',
                onPressed: () async {
                  await _scannerController?.toggleTorch();
                  setState(() => _isTorchOn = !_isTorchOn);
                },
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                icon: const Icon(Icons.flip_camera_android, size: 20),
                tooltip: 'Switch Camera',
                onPressed: () async {
                  await _scannerController?.switchCamera();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScannerOverlay() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 220,
          height: 140,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF22C55E), width: 2),
            borderRadius: BorderRadius.circular(12),
            color: Colors.black.withAlpha(20),
          ),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Container(width: 16, height: 16, decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFF22C55E), width: 4), left: BorderSide(color: Color(0xFF22C55E), width: 4)))),
              ),
              Align(
                alignment: Alignment.topRight,
                child: Container(width: 16, height: 16, decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFF22C55E), width: 4), right: BorderSide(color: Color(0xFF22C55E), width: 4)))),
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Container(width: 16, height: 16, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF22C55E), width: 4), left: BorderSide(color: Color(0xFF22C55E), width: 4)))),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Container(width: 16, height: 16, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF22C55E), width: 4), right: BorderSide(color: Color(0xFF22C55E), width: 4)))),
              ),
              Center(
                child: Container(
                  height: 1.5,
                  width: 190,
                  color: const Color(0xFF22C55E).withAlpha(180),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCameraFallbackView({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: const Color(0xFF0F172A),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF94A3B8), size: 40),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 14),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF168B45),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                onPressed: onAction,
                child: Text(actionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionToolbar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 450;
        final buttons = [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              if (_isCameraSupported) {
                setState(() {
                  _isCameraActive = !_isCameraActive;
                  if (_isCameraActive) _initScanner();
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Camera scanning is not supported on this platform.')),
                );
              }
            },
            icon: Icon(_isCameraActive ? Icons.videocam : Icons.videocam_off, color: const Color(0xFF168B45)),
            label: Text(_isCameraActive ? 'Camera On' : 'Camera Off'),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _pickImageAndScan,
            icon: const Icon(Icons.photo_library, color: Color(0xFF168B45)),
            label: const Text('Gallery / Image'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF168B45),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              _barcodeController.selection = TextSelection(baseOffset: 0, extentOffset: _barcodeController.text.length);
            },
            icon: const Icon(Icons.keyboard),
            label: const Text('Enter Barcode Manually'),
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
          alignment: WrapAlignment.center,
          children: buttons,
        );
      },
    );
  }

  Widget _buildManualInputCard() {
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
            'Manual Barcode Lookup',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _barcodeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Enter Barcode Number',
                    hintText: 'e.g. 8901030800012',
                    prefixIcon: Icon(Icons.pin),
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: _searchBarcode,
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF168B45),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _isLoading ? null : () => _searchBarcode(_barcodeController.text),
                icon: const Icon(Icons.search),
                label: const Text('Search Product'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetectedBarcodeBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF168B45), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Barcode detected: $_detectedBarcode',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF168B45), fontSize: 14),
            ),
          ),
          TextButton(
            onPressed: _resetScanner,
            child: const Text('Clear', style: TextStyle(color: Color(0xFF168B45))),
          ),
        ],
      ),
    );
  }

  Widget _buildProductResultCard() {
    final p = _foundProduct!;
    final name = p['name'] ?? 'Unknown Product';
    final barcode = p['barcode'] ?? '';
    final category = p['category'] ?? 'General';
    final brand = p['brand'] ?? '';
    final qty = (p['quantity'] as num?)?.toInt() ?? 0;
    final unit = p['unit'] ?? 'units';
    final price = (p['price'] as num?)?.toDouble() ?? 0.0;
    final expiryDate = p['expiryDate']?.toString() ?? 'N/A';
    final expiryStatus = (p['expiryStatus'] as String?)?.toUpperCase() ?? 'SAFE';
    final minStock = (p['minimumStock'] as num?)?.toInt() ?? 10;

    Color statusColor;
    if (expiryStatus == 'EXPIRED') {
      statusColor = const Color(0xFFDC2626);
    } else if (expiryStatus == 'CRITICAL') {
      statusColor = const Color(0xFFEA580C);
    } else if (expiryStatus == 'NEAR_EXPIRY') {
      statusColor = const Color(0xFFD97706);
    } else {
      statusColor = const Color(0xFF168B45);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  expiryStatus,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
              const Spacer(),
              Text(
                'Stock: $qty $unit',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 4),
          Text('Barcode: $barcode • Category: $category ${brand.isNotEmpty ? "• $brand" : ""}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const Divider(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 500;
              final details = [
                _detailColumn('Unit Price', '₹${price.toStringAsFixed(2)}'),
                _detailColumn('Expiry Date', expiryDate),
                _detailColumn('Stock Status', '$qty in stock (Min: $minStock)'),
              ];

              if (isWide) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: details,
                );
              }
              return Wrap(spacing: 24, runSpacing: 12, children: details);
            },
          ),
          const Divider(height: 24),
          Row(
            children: [
              const Text('Stock Adjustment: ', style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton.filledTonal(
                icon: const Icon(Icons.remove),
                onPressed: () => _updateQuantity(-1),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('$qty', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              IconButton.filledTonal(
                icon: const Icon(Icons.add),
                onPressed: () => _updateQuantity(1),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 450;
              final buttons = [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF168B45),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.of(context).pushNamed('/manager/ocr', arguments: p);
                  },
                  icon: const Icon(Icons.document_scanner),
                  label: const Text('OCR Verify Expiry'),
                ),
                OutlinedButton.icon(
                  onPressed: _resetScanner,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan Another Product'),
                ),
              ];

              if (isWide) {
                return Row(
                  children: [
                    Expanded(child: buttons[0]),
                    const SizedBox(width: 12),
                    Expanded(child: buttons[1]),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  buttons[0],
                  const SizedBox(height: 10),
                  buttons[1],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _detailColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
      ],
    );
  }

  Widget _buildNotFoundCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Column(
        children: [
          const Icon(Icons.warning_amber_rounded, size: 48, color: Color(0xFFEF4444)),
          const SizedBox(height: 12),
          const Text(
            'Product not found',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
          ),
          const SizedBox(height: 6),
          Text(
            _errorMessage ?? 'The scanned barcode is not registered in the catalog.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF7F1D1D)),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF168B45),
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final added = await Navigator.of(context).pushNamed(
                    '/manager/add-product',
                    arguments: {'barcode': _barcodeController.text},
                  );
                  if (added == true) {
                    _searchBarcode(_barcodeController.text);
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Product'),
              ),
              OutlinedButton.icon(
                onPressed: _resetScanner,
                icon: const Icon(Icons.refresh),
                label: const Text('Scan Again'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
