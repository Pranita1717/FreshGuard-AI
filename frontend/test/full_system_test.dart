import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/shelf_priority_screen.dart';
import 'package:frontend/screens/discounts_screen.dart';
import 'package:frontend/screens/restocking_screen.dart';
import 'package:frontend/screens/reports_screen.dart';
import 'package:frontend/screens/notifications_screen.dart';
import 'package:frontend/screens/employee_tasks_screen.dart';
import 'package:frontend/screens/employee_scanner_screen.dart';
import 'package:frontend/screens/remove_expired_screen.dart';
import 'package:frontend/screens/store_settings_screen.dart';
import 'package:frontend/widgets/app_shell.dart';
import 'package:frontend/screens/employee_inventory_screen.dart';
import 'package:frontend/services/session.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
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

  group('Full System Modules UI Verification', () {
    testWidgets('1. ShelfPriorityScreen mounts with AppShell title', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(const MaterialApp(home: ShelfPriorityScreen()));
      expect(find.byType(ShelfPriorityScreen), findsOneWidget);
      expect(find.text('Shelf Priority Triage'), findsOneWidget);
    });

    testWidgets('2. DiscountsScreen mounts with AppShell title', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(const MaterialApp(home: DiscountsScreen()));
      expect(find.byType(DiscountsScreen), findsOneWidget);
      expect(find.text('Discounts Management'), findsOneWidget);
    });

    testWidgets('3. RestockingScreen mounts with AppShell title', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(const MaterialApp(home: RestockingScreen()));
      expect(find.byType(RestockingScreen), findsOneWidget);
      expect(find.text('Restocking Intelligence'), findsOneWidget);
    });

    testWidgets('4. ReportsScreen mounts with AppShell title and export controls', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(const MaterialApp(home: ReportsScreen()));
      expect(find.byType(ReportsScreen), findsOneWidget);
      expect(find.text('Reports & PDF Export'), findsOneWidget);
    });

    testWidgets('5. NotificationsScreen mounts with AppShell title', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(const MaterialApp(home: NotificationsScreen()));
      expect(find.byType(NotificationsScreen), findsOneWidget);
      expect(find.text('Alerts & Notifications'), findsOneWidget);
    });

    testWidgets('6. EmployeeTasksScreen mounts with AppShell title', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(const MaterialApp(home: EmployeeTasksScreen()));
      expect(find.byType(EmployeeTasksScreen), findsOneWidget);
      expect(find.text('Duty & Task Board'), findsOneWidget);
    });

    testWidgets('7. EmployeeScannerScreen renders barcode input and lookup control', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(const MaterialApp(home: EmployeeScannerScreen()));
      await tester.pump();

      expect(find.byType(EmployeeScannerScreen), findsOneWidget);
      expect(find.text('Scan & Verify'), findsOneWidget);
      expect(find.text('Rapid Shelf Audit Barcode Scanner'), findsOneWidget);
      expect(find.text('Lookup'), findsOneWidget);
    });

    testWidgets('8. RemoveExpiredScreen mounts with AppShell title', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(const MaterialApp(home: RemoveExpiredScreen()));
      expect(find.byType(RemoveExpiredScreen), findsOneWidget);
      expect(find.text('Remove Expired Stock'), findsOneWidget);
    });

    testWidgets('9. StoreSettingsScreen renders user profile for store manager', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(const MaterialApp(home: StoreSettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(StoreSettingsScreen), findsOneWidget);
      expect(find.text('User Profile'), findsOneWidget);
      expect(find.text('User Profile Details'), findsOneWidget);
      expect(find.text('Staff Account Information'), findsOneWidget);
      expect(find.text('Backend API Host & Diagnostics'), findsNothing);
    });

    testWidgets('10. AppShell hides Notifications from Admin role but displays it for Store Manager', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      final session = Session();

      // Test as ADMIN
      await session.saveSession(
        token: "mock.jwt.token",
        id: "admin-1",
        name: "Admin User",
        email: "admin@freshguard.local",
        role: "ADMIN",
        storeName: "Headquarters",
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(1200, 900)),
            child: AppShell(
              title: 'Admin Dashboard',
              selectedIndex: 0,
              body: Text('Admin Content'),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('System Analytics'), findsOneWidget);
      expect(find.text('Notifications'), findsNothing);

      // Test as STORE_MANAGER
      await session.saveSession(
        token: "mock.jwt.token",
        id: "manager-1",
        name: "Store Manager",
        email: "manager@freshguard.local",
        role: "STORE_MANAGER",
        storeName: "Store 1",
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(1200, 900)),
            child: AppShell(
              title: 'Manager Dashboard',
              selectedIndex: 0,
              body: Text('Manager Content'),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Notifications'), findsOneWidget);
    });

    testWidgets('11. NotificationsScreen blocks ADMIN and displays Access Restricted notice', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      final session = Session();
      await session.saveSession(
        token: "mock.jwt.token",
        id: "admin-1",
        name: "Admin User",
        email: "admin@freshguard.local",
        role: "ADMIN",
        storeName: "Headquarters",
      );

      await tester.pumpWidget(const MaterialApp(home: NotificationsScreen()));
      await tester.pump();

      expect(find.text('Access Restricted to Store Operations'), findsOneWidget);
      expect(find.text('Return to Admin Dashboard'), findsOneWidget);
    });

    testWidgets('12. EmployeeInventoryScreen mounts with Stock Count Audit title', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(const MaterialApp(home: EmployeeInventoryScreen()));
      expect(find.byType(EmployeeInventoryScreen), findsOneWidget);
      expect(find.text('Stock Count Audit'), findsOneWidget);
    });
  });
}

