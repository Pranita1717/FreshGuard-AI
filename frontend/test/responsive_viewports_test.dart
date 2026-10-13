import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/services/session.dart';
import 'package:frontend/screens/admin_dashboard.dart';
import 'package:frontend/screens/manager_dashboard.dart';
import 'package:frontend/screens/employee_dashboard.dart';
import 'package:frontend/screens/restocking_screen.dart';
import 'package:frontend/screens/add_product_screen.dart';
import 'package:frontend/screens/edit_product_screen.dart';
import 'package:frontend/screens/barcode_scanner_screen.dart';
import 'package:frontend/screens/employee_scanner_screen.dart';
import 'package:frontend/screens/ocr_screen.dart';
import 'package:frontend/screens/shelf_priority_screen.dart';
import 'package:frontend/screens/discounts_screen.dart';
import 'package:frontend/screens/reports_screen.dart';
import 'package:frontend/screens/remove_expired_screen.dart';
import 'package:frontend/screens/store_settings_screen.dart';
import 'package:frontend/screens/notifications_screen.dart';
import 'package:frontend/screens/landing_screen.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/screens/register_screen.dart';

void main() {
  final viewports = [
    {'name': 'Mobile (360x640)', 'size': const Size(360, 640)},
    {'name': 'Tablet (768x1024)', 'size': const Size(768, 1024)},
    {'name': 'Desktop (1440x900)', 'size': const Size(1440, 900)},
  ];

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final session = Session();
    await session.init();
    await session.saveSession(
      token: "mock.jwt.token",
      id: "manager-1",
      name: "Store Manager",
      email: "manager@freshguard.local",
      role: "STORE_MANAGER",
      storeName: "FreshGuard Central Store",
    );
  });

  group('Zero-Overflow & Responsive Viewports Suite', () {
    for (final vp in viewports) {
      final size = vp['size'] as Size;
      final vpName = vp['name'] as String;

      Future<void> setViewport(WidgetTester tester) async {
        await tester.binding.setSurfaceSize(size);
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      }

      testWidgets('LandingScreen renders without overflow on $vpName', (tester) async {
        await setViewport(tester);
        await tester.pumpWidget(const MaterialApp(home: LandingScreen()));
        await tester.pump();
        expect(find.byType(LandingScreen), findsOneWidget);
        expect(find.text('FRESHGUARD'), findsOneWidget);
      });

      testWidgets('LoginScreen renders without overflow on $vpName', (tester) async {
        await setViewport(tester);
        await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
        await tester.pump();
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.text('Sign In'), findsOneWidget);
      });

      testWidgets('RegisterScreen renders without overflow on $vpName', (tester) async {
        await setViewport(tester);
        await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
        await tester.pump();
        expect(find.byType(RegisterScreen), findsOneWidget);
        expect(find.text('Staff Registration'), findsOneWidget);
      });

      testWidgets('RestockingScreen renders without overflow on $vpName', (tester) async {
        await setViewport(tester);
        await tester.pumpWidget(const MaterialApp(home: RestockingScreen()));
        await tester.pump();
        expect(find.byType(RestockingScreen), findsOneWidget);
        expect(find.text('Restocking Intelligence'), findsOneWidget);
      });

      testWidgets('AddProductScreen renders without overflow on $vpName', (tester) async {
        await setViewport(tester);
        await tester.pumpWidget(const MaterialApp(home: AddProductScreen()));
        await tester.pump();
        expect(find.byType(AddProductScreen), findsOneWidget);
        expect(find.text('Add Product to Inventory'), findsOneWidget);
        expect(find.text('Save Product'), findsOneWidget);
      });

      testWidgets('EditProductScreen renders without overflow on $vpName', (tester) async {
        await setViewport(tester);
        await tester.pumpWidget(
          MaterialApp(
            home: EditProductScreen(
              initialProduct: {
                'id': 'p-1',
                'name': 'Organic Whole Milk 1L',
                'barcode': '8901030800012',
                'category': 'Dairy & Eggs',
                'brand': 'FreshDairy',
                'quantity': 25,
                'unit': 'liters',
                'minimumStock': 10,
                'price': 3.99,
                'manufacturingDate': '2026-09-01',
                'expiryDate': '2026-10-15',
              },
            ),
          ),
        );
        await tester.pump();
        expect(find.byType(EditProductScreen), findsOneWidget);
        expect(find.text('Edit Product Details'), findsOneWidget);
        expect(find.text('Save Changes'), findsOneWidget);
      });

      testWidgets('BarcodeScannerScreen renders without overflow on $vpName', (tester) async {
        await setViewport(tester);
        await tester.pumpWidget(const MaterialApp(home: BarcodeScannerScreen()));
        await tester.pump();
        expect(find.byType(BarcodeScannerScreen), findsOneWidget);
        expect(find.text('Barcode Product Scanner'), findsOneWidget);
      });

      testWidgets('EmployeeScannerScreen renders without overflow on $vpName', (tester) async {
        await setViewport(tester);
        await tester.pumpWidget(const MaterialApp(home: EmployeeScannerScreen()));
        await tester.pump();
        expect(find.byType(EmployeeScannerScreen), findsOneWidget);
        expect(find.text('Scan & Verify'), findsOneWidget);
      });

      testWidgets('OcrScreen renders without overflow on $vpName', (tester) async {
        await setViewport(tester);
        await tester.pumpWidget(const MaterialApp(home: OcrScreen()));
        await tester.pump();
        expect(find.byType(OcrScreen), findsOneWidget);
        expect(find.text('OCR Expiry Date Extraction'), findsOneWidget);
      });

      testWidgets('ShelfPriorityScreen renders without overflow on $vpName', (tester) async {
        await setViewport(tester);
        await tester.pumpWidget(const MaterialApp(home: ShelfPriorityScreen()));
        await tester.pump();
        expect(find.byType(ShelfPriorityScreen), findsOneWidget);
        expect(find.text('Shelf Priority Triage'), findsOneWidget);
      });

      testWidgets('DiscountsScreen renders without overflow on $vpName', (tester) async {
        await setViewport(tester);
        await tester.pumpWidget(const MaterialApp(home: DiscountsScreen()));
        await tester.pump();
        expect(find.byType(DiscountsScreen), findsOneWidget);
        expect(find.text('Discounts Management'), findsOneWidget);
      });

      testWidgets('ReportsScreen renders without overflow on $vpName', (tester) async {
        await setViewport(tester);
        await tester.pumpWidget(const MaterialApp(home: ReportsScreen()));
        await tester.pump();
        expect(find.byType(ReportsScreen), findsOneWidget);
        expect(find.text('Reports & PDF Export'), findsOneWidget);
      });

      testWidgets('RemoveExpiredScreen renders without overflow on $vpName', (tester) async {
        await setViewport(tester);
        await tester.pumpWidget(const MaterialApp(home: RemoveExpiredScreen()));
        await tester.pump();
        expect(find.byType(RemoveExpiredScreen), findsOneWidget);
        expect(find.text('Remove Expired Stock'), findsOneWidget);
      });

      testWidgets('StoreSettingsScreen renders without overflow on $vpName', (tester) async {
        await setViewport(tester);
        await tester.pumpWidget(const MaterialApp(home: StoreSettingsScreen()));
        await tester.pump();
        expect(find.byType(StoreSettingsScreen), findsOneWidget);
      });

      testWidgets('NotificationsScreen renders without overflow on $vpName', (tester) async {
        await setViewport(tester);
        await tester.pumpWidget(const MaterialApp(home: NotificationsScreen()));
        await tester.pump();
        expect(find.byType(NotificationsScreen), findsOneWidget);
      });

      testWidgets('AdminDashboard renders without overflow on $vpName', (tester) async {
        final session = Session();
        await session.saveSession(
          token: "mock.jwt.token",
          id: "admin-1",
          name: "System Administrator",
          email: "admin@freshguard.local",
          role: "ADMIN",
          storeName: "Headquarters",
        );

        await setViewport(tester);
        await tester.pumpWidget(const MaterialApp(home: AdminDashboard()));
        await tester.pump();
        expect(find.byType(AdminDashboard), findsOneWidget);
      });

      testWidgets('ManagerDashboard renders without overflow on $vpName', (tester) async {
        final session = Session();
        await session.saveSession(
          token: "mock.jwt.token",
          id: "manager-1",
          name: "Store Manager",
          email: "manager@freshguard.local",
          role: "STORE_MANAGER",
          storeName: "Central Store",
        );

        await setViewport(tester);
        await tester.pumpWidget(const MaterialApp(home: ManagerDashboard()));
        await tester.pump();
        expect(find.byType(ManagerDashboard), findsOneWidget);
      });

      testWidgets('EmployeeDashboard renders without overflow on $vpName', (tester) async {
        final session = Session();
        await session.saveSession(
          token: "mock.jwt.token",
          id: "emp-1",
          name: "Floor Associate",
          email: "emp@freshguard.local",
          role: "EMPLOYEE",
          storeName: "Central Store",
        );

        await setViewport(tester);
        await tester.pumpWidget(const MaterialApp(home: EmployeeDashboard()));
        await tester.pump();
        expect(find.byType(EmployeeDashboard), findsOneWidget);
      });
    }
  });
}
