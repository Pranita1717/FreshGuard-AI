import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'session.dart';

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, [this.statusCode = 500]);

  @override
  String toString() => message;
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final Session _session = Session();

  Map<String, String> _buildHeaders({bool includeAuth = true}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth && _session.isLoggedIn) {
      headers['Authorization'] = 'Bearer ${_session.token}';
    }

    return headers;
  }

  dynamic _processResponse(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      body = response.body;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    // Auto-clear session on 401 Unauthorized
    if (response.statusCode == 401 && _session.isLoggedIn) {
      _session.clearSession();
    }

    String message = 'An error occurred (${response.statusCode})';
    if (body is Map && body.containsKey('message') && body['message'] != null) {
      message = body['message'].toString();
    } else if (response.statusCode == 401) {
      message = 'Invalid email or password';
    } else if (response.statusCode == 403) {
      message = 'Access denied: You do not have permission for this resource';
    } else if (response.statusCode == 404) {
      message = 'Requested resource not found';
    }

    throw ApiException(message, response.statusCode);
  }

  Future<dynamic> get(String endpoint) async {
    final url = Uri.parse('${ApiConfig.activeBaseUrl}$endpoint');
    try {
      final response = await http.get(url, headers: _buildHeaders());
      return _processResponse(response);
    } on http.ClientException catch (_) {
      throw ApiException('Unable to connect to FreshGuard server at ${ApiConfig.activeBaseUrl}. Please check backend is running.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  Future<dynamic> post(String endpoint, dynamic data, {bool includeAuth = true}) async {
    final url = Uri.parse('${ApiConfig.activeBaseUrl}$endpoint');
    try {
      final response = await http.post(
        url,
        headers: _buildHeaders(includeAuth: includeAuth),
        body: jsonEncode(data),
      );
      return _processResponse(response);
    } on http.ClientException catch (_) {
      throw ApiException('Unable to connect to FreshGuard server at ${ApiConfig.activeBaseUrl}. Please check backend is running.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  Future<dynamic> put(String endpoint, dynamic data) async {
    final url = Uri.parse('${ApiConfig.activeBaseUrl}$endpoint');
    try {
      final response = await http.put(
        url,
        headers: _buildHeaders(),
        body: jsonEncode(data),
      );
      return _processResponse(response);
    } on http.ClientException catch (_) {
      throw ApiException('Unable to connect to FreshGuard server at ${ApiConfig.activeBaseUrl}. Please check backend is running.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  Future<dynamic> delete(String endpoint) async {
    final url = Uri.parse('${ApiConfig.activeBaseUrl}$endpoint');
    try {
      final response = await http.delete(url, headers: _buildHeaders());
      return _processResponse(response);
    } on http.ClientException catch (_) {
      throw ApiException('Unable to connect to FreshGuard server at ${ApiConfig.activeBaseUrl}. Please check backend is running.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  // Auth Specific Methods
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await post('/auth/login', {
      'email': email.trim(),
      'password': password,
    }, includeAuth: false);

    final map = response as Map<String, dynamic>;
    await _session.saveSession(
      token: map['token'] ?? '',
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? '',
      storeName: map['storeName'] ?? '',
    );
    return map;
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String role,
    required String storeName,
    required String password,
    required String confirmPassword,
  }) async {
    final response = await post('/auth/register', {
      'name': name.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'role': role,
      'storeName': storeName.trim(),
      'password': password,
      'confirmPassword': confirmPassword,
    }, includeAuth: false);

    final map = response as Map<String, dynamic>;
    await _session.saveSession(
      token: map['token'] ?? '',
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? '',
      storeName: map['storeName'] ?? '',
    );
    return map;
  }

  // Profile
  Future<Map<String, dynamic>> getProfile() async {
    final res = await get('/auth/me');
    return res as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProfile({String? name, String? phone, String? storeName}) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (phone != null) data['phone'] = phone;
    if (storeName != null) data['storeName'] = storeName;
    final res = await put('/auth/profile', data);
    return res as Map<String, dynamic>;
  }

  // Products CRUD
  Future<List<dynamic>> getProducts() async {
    final res = await get('/products');
    return res as List<dynamic>;
  }

  Future<Map<String, dynamic>> getProduct(String id) async {
    final res = await get('/products/$id');
    return res as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> lookupBarcode(String barcode) async {
    final res = await get('/products/barcode/$barcode');
    return res as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> data) async {
    final res = await post('/products', data);
    return res as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProduct(String id, Map<String, dynamic> data) async {
    final res = await put('/products/$id', data);
    return res as Map<String, dynamic>;
  }

  Future<void> deleteProduct(String id) async {
    await delete('/products/$id');
  }

  // Inventory
  Future<Map<String, dynamic>> updateInventory(
    String id,
    String action,
    int qty,
    String? reason, {
    int? newQuantity,
  }) async {
    final body = <String, dynamic>{
      'action': action,
      'reason': reason ?? 'Inventory adjusted via console',
    };
    if (action.toUpperCase() == 'SET' || newQuantity != null) {
      body['newQuantity'] = newQuantity ?? qty;
      body['quantityChange'] = newQuantity ?? qty;
    } else {
      body['quantityChange'] = qty;
    }
    final res = await put('/inventory/$id', body);
    return res as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> removeExpiredProduct(String id, int qty, String? reason) async {
    final res = await post('/inventory/$id/remove-expired', {
      'quantity': qty,
      'reason': reason ?? 'Safe removal of expired items',
    });
    return res as Map<String, dynamic>;
  }

  Future<List<dynamic>> getInventoryLogs() async {
    final res = await get('/inventory/logs');
    return res as List<dynamic>;
  }

  Future<List<dynamic>> getRestocking() async {
    final res = await get('/inventory/restocking');
    return res as List<dynamic>;
  }

  // OCR
  Future<Map<String, dynamic>> extractOcr({String? text, List<int>? imageBytes, String? filename}) async {
    if (text != null && text.isNotEmpty) {
      final res = await post('/ocr/expiry', {'text': text});
      return res as Map<String, dynamic>;
    }

    final uri = Uri.parse('${ApiConfig.activeBaseUrl}/ocr/expiry');
    var request = http.MultipartRequest('POST', uri);
    if (_session.isLoggedIn) {
      request.headers['Authorization'] = 'Bearer ${_session.token}';
    }

    if (imageBytes != null && imageBytes.isNotEmpty) {
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: filename ?? 'product_label.jpg',
      ));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _processResponse(response) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProductExpiry(String id, String expiryDate, {String? ocrText}) async {
    final body = <String, dynamic>{
      'expiryDate': expiryDate,
    };
    if (ocrText != null) {
      body['ocrText'] = ocrText;
    }
    final res = await put('/products/$id/expiry', body);
    return res as Map<String, dynamic>;
  }

  // Discounts
  Future<List<dynamic>> getDiscounts() async {
    final res = await get('/discounts');
    return res as List<dynamic>;
  }

  Future<List<dynamic>> getDiscountSuggestions() async {
    final res = await get('/discounts/suggestions');
    return res as List<dynamic>;
  }

  Future<Map<String, dynamic>> createDiscount(String productId, double percentage, String reason) async {
    final res = await post('/discounts', {
      'productId': productId,
      'percentage': percentage,
      'reason': reason,
    });
    return res as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> approveDiscount(String id) async {
    final res = await put('/discounts/$id/approve', {});
    return res as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> rejectDiscount(String id) async {
    final res = await put('/discounts/$id/reject', {});
    return res as Map<String, dynamic>;
  }

  // Tasks
  Future<List<dynamic>> getTasks() async {
    final res = await get('/tasks');
    return res as List<dynamic>;
  }

  Future<List<dynamic>> getStoreEmployees() async {
    final res = await get('/tasks/employees');
    return res as List<dynamic>;
  }

  Future<Map<String, dynamic>> createTask(Map<String, dynamic> data) async {
    final res = await post('/tasks', data);
    return res as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateTaskStatus(String id, String status) async {
    final res = await put('/tasks/$id', {'status': status});
    return res as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> completeTask(String id) async {
    final res = await put('/tasks/$id/complete', {});
    return res as Map<String, dynamic>;
  }

  // Notifications
  Future<List<dynamic>> getNotifications() async {
    final res = await get('/notifications');
    return res as List<dynamic>;
  }

  Future<Map<String, dynamic>> markNotificationRead(String id) async {
    final res = await put('/notifications/$id/read', {});
    return res as Map<String, dynamic>;
  }

  Future<void> markAllNotificationsRead() async {
    await put('/notifications/read-all', {});
  }

  // Reports
  Future<Map<String, dynamic>> getReport(String type) async {
    final res = await get('/reports?type=$type');
    return res as Map<String, dynamic>;
  }

  String getReportPdfDownloadUrl(String type) {
    return '${ApiConfig.activeBaseUrl}/reports/pdf?type=$type';
  }
}
