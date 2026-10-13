import 'package:flutter/material.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _howItWorksKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _scrollToSection(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF168B45),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shield, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'FRESHGUARD',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFF0B6B35),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (MediaQuery.of(context).size.width >= 1000) ...[
            TextButton(
              onPressed: _scrollToTop,
              child: const Text('Home', style: TextStyle(color: Color(0xFF334155))),
            ),
            TextButton(
              onPressed: () => _scrollToSection(_featuresKey),
              child: const Text('Features', style: TextStyle(color: Color(0xFF334155))),
            ),
            TextButton(
              onPressed: () => _scrollToSection(_howItWorksKey),
              child: const Text('How It Works', style: TextStyle(color: Color(0xFF334155))),
            ),
            const SizedBox(width: 8),
          ],
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF168B45),
              side: const BorderSide(color: Color(0xFF168B45)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(context).pushNamed('/login'),
            child: const Text('Login'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF168B45),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(context).pushNamed('/register'),
            child: const Text('Register'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            _buildHero(context, isDesktop),
            Container(key: _featuresKey, child: _buildFeatures(context, isDesktop)),
            Container(key: _howItWorksKey, child: _buildHowItWorks(context, isDesktop)),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context, bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 60 : 20,
        vertical: isDesktop ? 70 : 40,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF0FDF4), Colors.white],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF168B45).withAlpha(25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF168B45).withAlpha(60)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified, size: 16, color: Color(0xFF168B45)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        MediaQuery.of(context).size.width < 400
                            ? 'Smart Expiry & Inventory System'
                            : 'Smart Food Expiry & Inventory Management System',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0B6B35),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Zero Food Waste.\nTotal Shelf Accountability.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width < 500 ? 30 : 42,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: const Text(
                  'Empower your supermarket operations with precise barcode cataloging, optical character recognition (OCR) for printed expiry dates, transparent rule-based shelf triage, and real-time inventory alerts.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF475569),
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 16,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF168B45),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                    ),
                    onPressed: () => Navigator.of(context).pushNamed('/login'),
                    icon: const Icon(Icons.storefront),
                    label: const Text('Open Store Portal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0B6B35),
                      side: const BorderSide(color: Color(0xFF168B45), width: 1.5),
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.of(context).pushNamed('/register'),
                    icon: const Icon(Icons.person_add_alt),
                    label: const Text('Staff Registration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatures(BuildContext context, bool isDesktop) {
    final features = [
      {
        'title': 'Inventory Management',
        'desc': 'Complete stock cataloging with unit pricing, categories, expiry details, and real-time count tracking.',
        'icon': Icons.inventory_2,
        'color': const Color(0xFF168B45),
      },
      {
        'title': 'Barcode Scanning',
        'desc': 'Instant barcode lookups via device camera or scanner gun for rapid shelf verification and stock updates.',
        'icon': Icons.qr_code_scanner,
        'color': const Color(0xFF0284C7),
      },
      {
        'title': 'OCR Date Extraction',
        'desc': 'Optical recognition of printed expiry dates from packaging images with user verification confirmation.',
        'icon': Icons.document_scanner,
        'color': const Color(0xFF8B5CF6),
      },
      {
        'title': 'Rule-Based Expiry Tracking',
        'desc': 'Deterministic date arithmetic classifying items into EXPIRED, CRITICAL (<7 days), NEAR EXPIRY, or SAFE.',
        'icon': Icons.hourglass_bottom,
        'color': const Color(0xFFE11D48),
      },
      {
        'title': 'Shelf Priority Triage',
        'desc': 'Automated HIGH, MEDIUM, and LOW priority badges ensuring expiring products are sold or discarded first.',
        'icon': Icons.low_priority,
        'color': const Color(0xFFD97706),
      },
      {
        'title': 'Notifications & Alerts',
        'desc': 'Automated warnings for critical expiry items, expired products needing disposal, and low-stock replenishment.',
        'icon': Icons.notifications_active,
        'color': const Color(0xFF0D9488),
      },
      {
        'title': 'Operational Reports & PDF',
        'desc': 'Generate executive inventory audits, expiry risk assessments, and downloadable PDF compliance reports.',
        'icon': Icons.picture_as_pdf,
        'color': const Color(0xFF4F46E5),
      },
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 60 : 20,
        vertical: 50,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              const Text(
                'Enterprise Supermarket Features',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Built for Store Managers and Employees to maintain 100% shelf compliance.',
                style: TextStyle(fontSize: 15, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 40),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: features.map((f) {
                  return SizedBox(
                    width: isDesktop ? 340 : double.infinity,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(6),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: (f['color'] as Color).withAlpha(25),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(f['icon'] as IconData, color: f['color'] as Color, size: 28),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            f['title'] as String,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            f['desc'] as String,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHowItWorks(BuildContext context, bool isDesktop) {
    final steps = [
      {'num': '1', 'title': 'Scan & Catalog', 'desc': 'Scan product barcodes and enter product and expiry details manually or with OCR assistance.'},
      {'num': '2', 'title': 'Automated Triage', 'desc': 'Rule-based date engine computes remaining days and flags shelf priority.'},
      {'num': '3', 'title': 'Action & Disposal', 'desc': 'Managers apply markdowns; employees safely discard expired stock with audit logs.'},
    ];

    return Container(
      color: const Color(0xFFF8FAF9),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 60 : 20,
        vertical: 50,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              const Text(
                'How FreshGuard Works',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 36),
              Wrap(
                spacing: 24,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: steps.map((s) {
                  return SizedBox(
                    width: isDesktop ? 290 : double.infinity,
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: const Color(0xFF168B45),
                          child: Text(
                            s['num']!,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          s['title']!,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          s['desc']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      color: const Color(0xFF0F172A),
      child: const Center(
        child: Text(
          'FRESHGUARD • MCA Project • Smart Food Expiry & Inventory Management System',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
