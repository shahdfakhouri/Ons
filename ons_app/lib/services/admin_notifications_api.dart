import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:ons_app/core/constants/api_config.dart';
import 'package:ons_app/services/auth_service.dart';

class AdminNotificationsApi {
  final http.Client _client;
  AdminNotificationsApi({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> _headers() {
    final token = AuthService().token;
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Uri _url(String path) => Uri.parse('${ApiConfig.notificationsBase}$path');

  dynamic _decode(http.Response res) {
    final body = res.body.isNotEmpty ? jsonDecode(res.body) : null;
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    throw Exception('HTTP ${res.statusCode}: ${res.body}');
  }

  // GET /api/notifications/admin
  Future<List<Map<String, dynamic>>> getAdminNotifications() async {
    final res = await _client.get(_url('/admin'), headers: _headers());
    final j = _decode(res);
    final list = (j is Map ? (j['notifications'] as List? ?? []) : <dynamic>[]);
    return list.cast<Map<String, dynamic>>();
  }

  // GET /api/notifications/admin/health?status=open|resolved|all
  Future<List<Map<String, dynamic>>> getHealthAlerts({String status = 'open'}) async {
    final q = status.isEmpty ? '' : '?status=${Uri.encodeComponent(status)}';
    final res = await _client.get(_url('/admin/health$q'), headers: _headers());
    final j = _decode(res);
    final list = (j is Map ? (j['alerts'] as List? ?? []) : <dynamic>[]);
    return list.cast<Map<String, dynamic>>();
  }

  // PATCH /api/notifications/admin/:id/read
  Future<void> markAsRead(int id) async {
    final res = await _client.patch(_url('/admin/$id/read'), headers: _headers());
    _decode(res);
  }

  // PATCH /api/notifications/admin/:id/resolve
  Future<void> resolveAlert(int id) async {
    final res = await _client.patch(_url('/admin/$id/resolve'), headers: _headers());
    _decode(res);
  }
}
