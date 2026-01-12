import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:ons_app/core/constants/api_config.dart';
import 'package:ons_app/services/auth_service.dart';

class MatchApi {
  final http.Client _client;
  MatchApi({http.Client? client}) : _client = client ?? http.Client();

  String get _base => '${ApiConfig.baseUrl}/api/match';

  Map<String, String> _headers() {
    final token = AuthService().token;
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

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

  /// POST /api/match/find-match/:family_id
  Future<List<Map<String, dynamic>>> findBestMatch(String familyId) async {
    final uri = Uri.parse('$_base/find-match/$familyId');
    final res = await _client.post(uri, headers: _headers());
    final j = _decode(res);
    final list = (j['matches'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}
