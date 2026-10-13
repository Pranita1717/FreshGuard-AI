import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:frontend/screens/admin_dashboard.dart';
import 'package:frontend/screens/landing_screen.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/screens/register_screen.dart';
import 'package:frontend/services/session.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final session = Session();
    await session.init();
    await session.clearSession();
  });

  group('Phase 2 UI & Navigation Tests', () {
    testWidgets('1. Landing Screen renders hero, features, and auth action buttons', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      final session = Session();
      await tester.pumpWidget(FreshGuardApp(initialSession: session));
      await tester.pumpAndSettle();

      expect(find.byType(LandingScreen), findsOneWidget);
      expect(find.text('FRESHGUARD'), findsWidgets);
      expect(find.text('Zero Food Waste.\nTotal Shelf Accountability.'), findsOneWidget);
      expect(find.text('Open Store Portal'), findsOneWidget);
      expect(find.text('Staff Registration'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Register'), findsOneWidget);
    });

    testWidgets('2. Login Screen validation triggers on empty fields', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sign in to access your store dashboard'), findsOneWidget);

      // Tap Sign In with empty fields
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('3. Login Screen accepts valid credentials input', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'admin@freshguard.local');
      await tester.enterText(find.byType(TextFormField).at(1), 'Admin@123');
      await tester.pumpAndSettle();

      expect(find.text('admin@freshguard.local'), findsOneWidget);
    });

    testWidgets('4. Registration Screen enforces employee/manager roles and blocks admin', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(
        const MaterialApp(
          home: RegisterScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Staff Registration'), findsOneWidget);
      expect(find.text('Store Employee (Scanning & Stocking)'), findsOneWidget);

      // Open Dropdown
      await tester.tap(find.text('Store Employee (Scanning & Stocking)'));
      await tester.pumpAndSettle();

      // Only Employee and Store Manager should be visible
      expect(find.text('Store Manager (Full Inventory Control)'), findsWidgets);
      expect(find.text('System Administrator'), findsNothing);
      expect(find.text('ADMIN'), findsNothing);
    });

    testWidgets('5. Session management correctly stores and clears JWT token', (tester) async {
      final session = Session();
      expect(session.isLoggedIn, isFalse);

      await session.saveSession(
        token: 'mock.jwt.token.phase2',
        id: 'user-123',
        name: 'Test Manager',
        email: 'manager@freshguard.local',
        role: 'STORE_MANAGER',
        storeName: 'Downtown Supermarket',
      );

      expect(session.isLoggedIn, isTrue);
      expect(session.isManager, isTrue);
      expect(session.isAdmin, isFalse);
      expect(session.role, 'STORE_MANAGER');
      expect(session.storeName, 'Downtown Supermarket');

      await session.clearSession();
      expect(session.isLoggedIn, isFalse);
      expect(session.token, isNull);
    });

    testWidgets('6. Role-based routing resolves dashboard for Admin session', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      final session = Session();
      await session.saveSession(
        token: 'mock.jwt.token',
        id: 'admin-1',
        name: 'Administrator',
        email: 'admin@freshguard.local',
        role: 'ADMIN',
        storeName: 'Headquarters',
      );

      await tester.pumpWidget(FreshGuardApp(initialSession: session));
      await tester.pump();

      expect(find.byType(AdminDashboard), findsOneWidget);
    });
  });
}
