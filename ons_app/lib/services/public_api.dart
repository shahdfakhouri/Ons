import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:ons_app/core/constants/api_config.dart';
import 'package:ons_app/services/auth_service.dart';

class PublicApi {
  final http.Client _client;
  PublicApi({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> _headers() {
    // endpoints are public, but if token exists it's fine to send it
    final token = AuthService().token;
    return {
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _decodeObj(http.Response res) {
    final dynamic decoded = res.body.isNotEmpty ? jsonDecode(res.body) : {};
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return decoded is Map<String, dynamic> ? decoded : {'data': decoded};
    }
    final msg = (decoded is Map && decoded['msg'] != null)
        ? decoded['msg'].toString()
        : 'Request failed (${res.statusCode})';
    throw Exception(msg);
  }

  Future<Map<String, dynamic>> getCaregiverReviews(int caregiverId) async {
    final uri = Uri.parse('${ApiConfig.apiBase}/caregivers/$caregiverId/reviews');
    final res = await _client.get(uri, headers: _headers());
    return _decodeObj(res);
  }

  Future<Map<String, dynamic>> getRetirementHomeReviews(int homeId) async {
    final uri = Uri.parse('${ApiConfig.apiBase}/retirement-homes/$homeId/reviews');
    final res = await _client.get(uri, headers: _headers());
    return _decodeObj(res);
  }
}
