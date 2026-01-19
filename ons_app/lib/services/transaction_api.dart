import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ons_app/core/constants/api_config.dart';
import 'package:ons_app/services/auth_service.dart';

class TransactionApi {
  final http.Client _client;
  TransactionApi({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> _headers() {
    final token = AuthService().token;
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Uri _url(String path) => Uri.parse('${ApiConfig.transactionsBase}$path');

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

  Future<Map<String, dynamic>> post(String path, {Object? body}) async {
    final res = await _client.post(
      _url(path),
      headers: _headers(),
      body: jsonEncode(body ?? {}),
    );
    return _decode(res);
  }

  Future<void> payFreelancer({
    required int caregiverId,
    required num amount,
    required String method,
  }) async {
    await post('/pay-freelancer', body: {
      'caregiver_id': caregiverId,
      'amount': amount,
      'method': method,
    });
  }

  Future<void> payHome({
    required int homeId,
    required int caregiverId,
    required num amount,
    required String method,
  }) async {
    await post('/pay-home', body: {
      'home_id': homeId,
      'caregiver_id': caregiverId,
      'amount': amount,
      'method': method,
    });
  }

  Future<void> payMedicine({
    required int medicineId,
    required num amount,
    required String method,
  }) async {
    await post('/pay-medicine', body: {
      'medicine_id': medicineId,
      'amount': amount,
      'method': method,
    });
  }
}
