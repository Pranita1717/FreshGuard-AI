import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Session with ChangeNotifier {
  static final Session _instance = Session._internal();
  factory Session() => _instance;
  Session._internal();

  String? _token;
  String? _id;
  String? _name;
  String? _email;
  String? _role;
  String? _storeName;

  String? get token => _token;
  String? get id => _id;
  String? get name => _name;
  String? get email => _email;
  String? get role => _role;
  String? get storeName => _storeName;

  bool get isLoggedIn => _token != null && _token!.isNotEmpty;
  bool get isAdmin => _role == 'ADMIN';
  bool get isManager => _role == 'STORE_MANAGER';
  bool get isEmployee => _role == 'EMPLOYEE';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _id = prefs.getString('user_id');
    _name = prefs.getString('user_name');
    _email = prefs.getString('user_email');
    _role = prefs.getString('user_role');
    _storeName = prefs.getString('user_store_name');
    notifyListeners();
  }

  Future<void> saveSession({
    required String token,
    required String id,
    required String name,
    required String email,
    required String role,
    required String storeName,
  }) async {
    _token = token;
    _id = id;
    _name = name;
    _email = email;
    _role = role;
    _storeName = storeName;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('user_id', id);
    await prefs.setString('user_name', name);
    await prefs.setString('user_email', email);
    await prefs.setString('user_role', role);
    await prefs.setString('user_store_name', storeName);

    notifyListeners();
  }

  Future<void> clearSession() async {
    _token = null;
    _id = null;
    _name = null;
    _email = null;
    _role = null;
    _storeName = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_role');
    await prefs.remove('user_store_name');

    notifyListeners();
  }
}
