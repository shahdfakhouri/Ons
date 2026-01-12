// lib/services/elder_entertainment_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:ons_app/core/constants/api_config.dart';
import 'package:ons_app/services/elder_auth_service.dart';

class ElderEntertainmentApi {
  final _auth = ElderAuthService();

  Map<String, String> _headers() {
    final h = {'Content-Type': 'application/json', 'Accept': 'application/json'};
    final t = _auth.token;
    if (t != null && t.isNotEmpty) h['Authorization'] = 'Bearer $t';
    return h;
  }

  dynamic _decode(http.Response res) {
    final body = res.body.isNotEmpty ? jsonDecode(res.body) : null;
    if (res.statusCode >= 200 && res.statusCode < 300) return body;

    final msg = (body is Map && body['msg'] != null)
        ? body['msg'].toString()
        : 'Request failed (${res.statusCode})';
    throw Exception(msg);
  }

  // GET /feed
  Future<List<dynamic>> getFeed() async {
    final url = Uri.parse('${ApiConfig.entertainmentBase}/feed');
    final res = await http.get(url, headers: _headers());
    final data = _decode(res);
    if (data is Map && data['items'] is List) return data['items'] as List;
    return [];
  }

  // POST /favorites/:item_id
  Future<void> addFavorite(int itemId) async {
    final url = Uri.parse('${ApiConfig.entertainmentBase}/favorites/$itemId');
    final res = await http.post(url, headers: _headers());
    _decode(res);
  }

  // GET /favorites
  Future<List<dynamic>> getFavorites() async {
    final url = Uri.parse('${ApiConfig.entertainmentBase}/favorites');
    final res = await http.get(url, headers: _headers());
    final data = _decode(res);
    if (data is Map && data['favorites'] is List) return data['favorites'] as List;
    return [];
  }

  // DELETE /favorites/:item_id
  Future<void> removeFavorite(int itemId) async {
    final url = Uri.parse('${ApiConfig.entertainmentBase}/favorites/$itemId');
    final res = await http.delete(url, headers: _headers());
    _decode(res);
  }

  // POST /activity
  Future<void> upsertActivity({
    required int itemId,
    String activityType = 'watched',
    String status = 'started',
    double? progressPercent,
    int? lastPositionSec,
    String? notes,
  }) async {
    final url = Uri.parse('${ApiConfig.entertainmentBase}/activity');
    final res = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({
        'item_id': itemId,
        'activity_type': activityType,
        'status': status,
        'progress_percent': progressPercent,
        'last_position_sec': lastPositionSec,
        'notes': notes,
      }),
    );
    _decode(res);
  }

  // GET /activity
  Future<List<dynamic>> getActivity() async {
    final url = Uri.parse('${ApiConfig.entertainmentBase}/activity');
    final res = await http.get(url, headers: _headers());
    final data = _decode(res);
    if (data is Map && data['activity'] is List) return data['activity'] as List;
    return [];
  }

  // GET /continue
  Future<List<dynamic>> getContinue() async {
    final url = Uri.parse('${ApiConfig.entertainmentBase}/continue');
    final res = await http.get(url, headers: _headers());
    final data = _decode(res);
    if (data is Map && data['continue'] is List) return data['continue'] as List;
    return [];
  }
}
