import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ons_app/core/constants/api_config.dart';
import 'package:ons_app/services/auth_service.dart';

class PaymentApi {
  final http.Client _client;
  PaymentApi({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> _headers() {
    final token = AuthService().token;
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Uri _url(String path) => Uri.parse('${ApiConfig.paymentsBase}$path');

  Map<String, dynamic> _decode(http.Response res) {
    final dynamic decoded = res.body.isNotEmpty ? jsonDecode(res.body) : {};
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return decoded is Map<String, dynamic> ? decoded : {'data': decoded};
    }
    final msg = (decoded is Map && decoded['msg'] != null)
        ? decoded['msg'].toString()
        : 'Request failed (${res.statusCode})';
    throw Exception(msg);
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, String>? query}) async {
    final uri = _url(path).replace(queryParameters: query);
    final res = await _client.get(uri, headers: _headers());
    return _decode(res);
  }

  Future<Map<String, dynamic>> post(String path, {Object? body}) async {
    final res = await _client.post(
      _url(path),
      headers: _headers(),
      body: jsonEncode(body ?? {}),
    );
    return _decode(res);
  }

  // Existing (receiver endpoints)
  Future<Map<String, dynamic>> getReceiverRevenue() async {
    return await get('/receiver-revenue');
  }

  Future<List<Map<String, dynamic>>> getReceiverTransactions({int limit = 50}) async {
    final j = await get('/receiver-transactions', query: {'limit': '$limit'});
    final list = (j['transactions'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // ✅ NEW: PayPal create order (returns approveUrl + orderId)
  Future<Map<String, dynamic>> createPayPalOrder({
    required int paymentId,
    required num amount,
  }) async {
    // POST /api/payments/create
    return await post('/create', body: {
      'paymentId': paymentId,
      'amount': amount,
    });
  }

  // ✅ NEW: PayPal capture order (finalizes DB payment + inserts transactions)
  Future<Map<String, dynamic>> capturePayPal({
    required String orderId,
    required int paymentId,
  }) async {
    // GET /api/payments/capture?orderId=...&paymentId=...
    return await get('/capture', query: {
      'orderId': orderId,
      'paymentId': paymentId.toString(),
    });
  }
}