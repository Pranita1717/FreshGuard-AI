import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api.dart';
import '../widgets/app_shell.dart';

class EmployeeScannerScreen extends StatefulWidget {
  const EmployeeScannerScreen({super.key});

  @override
  State<EmployeeScannerScreen> createState() => _EmployeeScannerScreenState();
}

class _EmployeeScannerScreenState extends State<EmployeeScannerScreen> with WidgetsBindingObserver {
  final TextEditingController _barcodeCtrl = TextEditingController();
  final _picker = ImagePicker();

  MobileScannerController? _scannerController;
  bool _isCameraActive = true;
  bool _isTorchOn = false;
  bool _hasPermissionError = false;

  bool _isLoading = false;
  bool _isProcessingScan = false;
  String? _detectedBarcode;
  Map<String, dynamic>? _scannedProduct;
  String? _errorMessage;

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
    return true;
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
    _barcodeCtrl.dispose();
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
      _barcodeCtrl.text = code;
    });

    await _lookupBarcode(code);
  }

  Future<void> _lookupBarcode(String barcode) async {
    final code = barcode.trim();
    if (code.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _scannedProduct = null;
    });

    try {
      final product = await ApiService().lookupBarcode(code);
      if (!mounted) return;
      setState(() {
        _scannedProduct = product;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.statusCode == 404
            ? 'Product barcode "$code" is not registered in the inventory catalog. Please inform your Store Manager to register this SKU.'
            : e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Scan query failed: $e';
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
        _scannedProduct = null;
      });

      if (_isCameraSupported && _scannerController != null) {
        final capture = await _scannerController!.analyzeImage(file.path);
        if (capture != null && capture.barcodes.isNotEmpty) {
          final code = capture.barcodes.first.rawValue;
          if (code != null && code.isNotEmpty) {
            setState(() {
              _detectedBarcode = code;
              _barcodeCtrl.text = code;
            });
            await _lookupBarcode(code);
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

  Future<void> _adjustStock(int delta) async {
    if (_scannedProduct == null) return;
    final current = (_scannedProduct!['quantity'] as num?)?.toInt() ?? 0;
    final newQty = current + delta;
    if (newQty < 0) return;

    try {
      final updated = await ApiService().updateInventory(
        _scannedProduct!['id'] ?? _scannedProduct!['productId'],
        delta > 0 ? 'INCREASE' : 'DECREASE',
        delta.abs(),
        'Rapid shelf stock adjustment by staff',
      );
      if (!mounted) return;
      setState(() {
        _scannedProduct = updated;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Shelf count updated to $newQty units!'),
          backgroundColor: const Color(0xFF168B45),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _resetScanner() {
    setState(() {
      _scannedProduct = null;
      _errorMessage = null;
      _detectedBarcode = null;
      _isProcessingScan = false;
      _barcodeCtrl.clear();
      _isCameraActive = true;
    });
    if (_isCameraSupported) {
      _initScanner();
    }
  }

  Widget _buildShelfAdvice(String status, int? days) {
    Color bg;
    Color border;
    IconData icon;
    String header;
    String advice;

    if (status == 'EXPIRED' || (days != null && days < 0)) {
      bg = const Color(0xFFFEF2F2);
      border = const Color(0xFFFCA5A5);
      icon = Icons.cancel;
      header = 'PULL FROM SHELF IMMEDIATELY';
      advice = 'Product is expired. Do NOT sell to customers. Transfer to disposal bin.';
    } else if (status == 'CRITICAL' || (days != null && days <= 7)) {
      bg = const Color(0xFFFFFBEB);
      border = const Color(0xFFFCD34D);
      icon = Icons.priority_high;
      header = 'MOVE TO FRONT OF SHELF (FIFO)';
      advice = 'Expires within 7 days. Shift to eye-level front row. Verify markdown discount tag is attached.';
    } else if (status == 'NEAR_EXPIRY' || (days != null && days <= 30)) {
      bg = const Color(0xFFF0FDF4);
      border = const Color(0xFF86EFAC);
      icon = Icons.low_priority;
      header = 'ROTATE STOCK (FIFO)';
      advice = 'Rotate stock forward. Ensure older stock sits in front of newer deliveries.';
    } else {
      bg = const Color(0xFFF8FAFC);
      border = const Color(0xFFE2E8F0);
      icon = Icons.check_circle_outline;
      header = 'STANDARD STOCKING';
      advice = 'Safe shelf life (>30 days). Place behind near-expiry stock.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: border == const Color(0xFFFCA5A5) ? Colors.red : const Color(0xFF168B45), size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  header,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                ),
                SizedBox(height: 4),
                Text(advice, style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Scan & Verify',
      selectedIndex: 2,
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
                _buildCameraCard(),
                const SizedBox(height: 16),
                _buildActionToolbar(),
                const SizedBox(height: 20),
                _buildManualInputCard(),
                const SizedBox(height: 20),
                if (_detectedBarcode != null && _detectedBarcode!.isNotEmpty) ...[
                  _buildDetectedBanner(),
                  const SizedBox(height: 16),
                ],
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(color: Color(0xFF168B45)),
                    ),
                  )
                else if (_scannedProduct != null)
                  _buildProductCard()
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
                  'Rapid Shelf Audit Barcode Scanner',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                SizedBox(height: 4),
                Text(
                  'Scan product barcode to instantly verify shelf position triage, expiry status, and stock count.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraCard() {
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
      return _buildCameraFallback(
        icon: Icons.computer,
        title: 'Camera scanning is unavailable on this platform.',
        subtitle: 'Desktop environments do not support direct camera scanning. Use manual barcode entry below.',
      );
    }

    if (_hasPermissionError) {
      return _buildCameraFallback(
        icon: Icons.videocam_off,
        title: 'Camera permission is required to scan barcodes.',
        subtitle: 'Please grant camera access to perform shelf scans.',
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
      return _buildCameraFallback(
        icon: Icons.videocam_outlined,
        title: 'Camera scanner is currently paused.',
        subtitle: 'Tap below to resume shelf scanning.',
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
            return _buildCameraFallback(
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
              Align(alignment: Alignment.topLeft, child: Container(width: 16, height: 16, decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFF22C55E), width: 4), left: BorderSide(color: Color(0xFF22C55E), width: 4))))),
              Align(alignment: Alignment.topRight, child: Container(width: 16, height: 16, decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFF22C55E), width: 4), right: BorderSide(color: Color(0xFF22C55E), width: 4))))),
              Align(alignment: Alignment.bottomLeft, child: Container(width: 16, height: 16, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF22C55E), width: 4), left: BorderSide(color: Color(0xFF22C55E), width: 4))))),
              Align(alignment: Alignment.bottomRight, child: Container(width: 16, height: 16, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF22C55E), width: 4), right: BorderSide(color: Color(0xFF22C55E), width: 4))))),
              Center(child: Container(height: 1.5, width: 190, color: const Color(0xFF22C55E).withAlpha(180))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCameraFallback({
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
            Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 14),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF168B45), foregroundColor: Colors.white),
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
              _barcodeCtrl.selection = TextSelection(baseOffset: 0, extentOffset: _barcodeCtrl.text.length);
            },
            icon: const Icon(Icons.keyboard),
            label: const Text('Enter Barcode Manually'),
          ),
        ];

        if (isNarrow) {
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: buttons.map((b) => Padding(padding: const EdgeInsets.only(bottom: 8), child: b)).toList());
        }
        return Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: buttons);
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
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _barcodeCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Enter SKU Barcode Number',
                hintText: 'e.g. 8901030800012',
                prefixIcon: Icon(Icons.pin),
                border: OutlineInputBorder(),
              ),
              onSubmitted: _lookupBarcode,
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF168B45),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _isLoading ? null : () => _lookupBarcode(_barcodeCtrl.text),
            icon: const Icon(Icons.search),
            label: const Text('Lookup'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectedBanner() {
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

  Widget _buildProductCard() {
    final p = _scannedProduct!;
    final status = (p['expiryStatus'] as String?)?.toUpperCase() ?? 'SAFE';
    final days = (p['daysUntilExpiry'] as num?)?.toInt();
    final qty = (p['quantity'] as num?)?.toInt() ?? 0;
    final unit = p['unit'] ?? 'units';

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
          _buildShelfAdvice(status, days),
          const SizedBox(height: 18),
          Text(p['name'] ?? 'Product', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 4),
          Text('Barcode: ${p['barcode']} • Category: ${p['category']}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Shelf Expiry Date', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Text(p['expiryDate']?.toString() ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Audit Status', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Text(status, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF168B45))),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Current Stock', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Text('$qty $unit', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              const Text('Adjust Shelf Quantity: ', style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton.filledTonal(
                icon: const Icon(Icons.remove),
                onPressed: () => _adjustStock(-1),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('$qty', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              IconButton.filledTonal(
                icon: const Icon(Icons.add),
                onPressed: () => _adjustStock(1),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _resetScanner,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan Another SKU'),
            ),
          ),
        ],
      ),
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
          const Text('Product not found', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF991B1B))),
          const SizedBox(height: 6),
          Text(_errorMessage ?? 'Not found in inventory catalog.', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Color(0xFF7F1D1D))),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _resetScanner,
            icon: const Icon(Icons.refresh),
            label: const Text('Scan Again'),
          ),
        ],
      ),
    );
  }
}
