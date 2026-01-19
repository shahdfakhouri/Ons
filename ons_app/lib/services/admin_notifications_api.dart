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

  // GET /api/notifications/admin (Separated System Events)
  Future<List<Map<String, dynamic>>> getAdminNotifications({
    String? severity,
    String? role,
    String? startDate,
    String? endDate,
  }) async {
    final Map<String, String> queryParams = {
      if (severity != null && severity != 'all') 'severity': severity,
      if (role != null && role != 'all') 'role': role,
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
    };

    String queryString = queryParams.isNotEmpty 
        ? '?' + queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&') 
        : '';

    final res = await _client.get(_url('/admin$queryString'), headers: _headers());
    final j = _decode(res);
    final list = (j is Map ? (j['notifications'] as List? ?? []) : <dynamic>[]);
    return list.cast<Map<String, dynamic>>();
  }

  // GET /api/notifications/admin/health (Medical Action Tab)
  Future<List<Map<String, dynamic>>> getHealthAlerts({
    String status = 'open',
    String? severity,
    String? startDate,
    String? endDate,
  }) async {
    final Map<String, String> queryParams = {
      'status': status,
      if (severity != null && severity != 'all') 'severity': severity,
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
    };
    
    final queryString = '?' + queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    
    final res = await _client.get(_url('/admin/health$queryString'), headers: _headers());
    final j = _decode(res);
    final list = (j is Map ? (j['alerts'] as List? ?? []) : <dynamic>[]);
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> markAsRead(int id) async => _decode(await _client.patch(_url('/admin/$id/read'), headers: _headers()));
  Future<void> resolveAlert(int id) async => _decode(await _client.patch(_url('/admin/$id/resolve'), headers: _headers()));
}