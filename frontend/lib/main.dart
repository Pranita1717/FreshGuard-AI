import 'package:flutter/material.dart';
import 'screens/add_product_screen.dart';
import 'screens/admin_dashboard.dart';
import 'screens/barcode_scanner_screen.dart';
import 'screens/discounts_screen.dart';
import 'screens/employee_dashboard.dart';
import 'screens/employee_inventory_screen.dart';
import 'screens/employee_scanner_screen.dart';
import 'screens/employee_tasks_screen.dart';
import 'screens/edit_product_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/login_screen.dart';
import 'screens/manager_dashboard.dart';
import 'screens/manager_tasks_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/ocr_screen.dart';
import 'screens/register_screen.dart';
import 'screens/remove_expired_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/restocking_screen.dart';
import 'screens/shelf_priority_screen.dart';
import 'screens/store_settings_screen.dart';
import 'services/session.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final session = Session();
  await session.init();

  runApp(FreshGuardApp(initialSession: session));
}

class FreshGuardApp extends StatelessWidget {
  final Session initialSession;

  const FreshGuardApp({super.key, required this.initialSession});

  String _determineInitialRoute() {
    if (!initialSession.isLoggedIn) {
      return '/';
    }
    final role = initialSession.role;
    if (role == 'ADMIN') return '/admin';
    if (role == 'STORE_MANAGER') return '/manager';
    if (role == 'EMPLOYEE') return '/employee';
    return '/';
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FreshGuard - Food Expiry & Inventory Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF168B45),
          primary: const Color(0xFF168B45),
          secondary: const Color(0xFF0B6B35),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAF9),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 1,
          iconTheme: IconThemeData(color: Color(0xFF1E293B)),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF168B45),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF168B45), width: 1.5),
          ),
        ),
      ),
      initialRoute: _determineInitialRoute(),
      routes: {
        '/': (context) => const LandingScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        
        // Admin
        '/admin': (context) => const AdminDashboard(),
        '/admin/analytics': (context) => const AdminDashboard(selectedIndex: 1),
        
        // Store Manager
        '/manager': (context) => const ManagerDashboard(),
        '/manager/tasks': (context) => const ManagerTasksScreen(),
        '/manager/inventory': (context) => const InventoryScreen(),
        '/manager/add-product': (context) => const AddProductScreen(),
        '/manager/edit-product': (context) => const EditProductScreen(),
        // Backward-compatible aliases used by older screen code.
        '/products': (context) => const AddProductScreen(),
        '/manager/scan-barcode': (context) => const BarcodeScannerScreen(),
        '/manager/barcode': (context) => const BarcodeScannerScreen(),
        '/manager/ocr': (context) => const OcrScreen(),
        '/manager/shelf-priority': (context) => const ShelfPriorityScreen(),
        '/manager/discounts': (context) => const DiscountsScreen(),
        '/manager/restocking': (context) => const RestockingScreen(),
        '/manager/reports': (context) => const ReportsScreen(),
        '/manager/notifications': (context) => const NotificationsScreen(),
        
        // Employee
        '/employee': (context) => const EmployeeDashboard(),
        '/employee/tasks': (context) => const EmployeeTasksScreen(),
        '/employee/scanner': (context) => const EmployeeScannerScreen(),
        '/employee/inventory': (context) => const EmployeeInventoryScreen(),
        '/employee/remove-expired': (context) => const RemoveExpiredScreen(),
        '/employee/notifications': (context) => const NotificationsScreen(),
        
        // Common
        '/notifications': (context) => const NotificationsScreen(),
        '/settings': (context) => const StoreSettingsScreen(),
      },
    );
  }
}
