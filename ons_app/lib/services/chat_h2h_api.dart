import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:ons_app/core/constants/api_config.dart';
import 'package:ons_app/services/auth_service.dart';

class ChatH2HApi {
  final http.Client _client;
  ChatH2HApi({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> _headers() {
    final token = AuthService().token;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Uri _url(String path) => Uri.parse('${ApiConfig.chatH2HBase}$path');

  void _throwIfBad(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    throw Exception('HTTP ${res.statusCode}: ${res.body}');
  }

  Future<Map<String, dynamic>> createOrGetConversation({
    required int elderId,
    required int caregiverId,
    required int familyId,
  }) async {
    final res = await _client.post(
      _url('/conversations'),
      headers: _headers(),
      body: jsonEncode({
        'elderId': elderId,
        'caregiverId': caregiverId,
        'familyId': familyId,
      }),
    );
    _throwIfBad(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<List<dynamic>> listConversations() async {
    final res = await _client.get(_url('/conversations'), headers: _headers());
    _throwIfBad(res);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['conversations'] as List<dynamic>? ?? []);
  }

  Future<List<dynamic>> getMessages(
    String conversationId, {
    int limit = 30,
    DateTime? before,
  }) async {
    final qp = <String, String>{'limit': '$limit'};
    if (before != null) qp['before'] = before.toIso8601String();

    final uri = _url('/conversations/$conversationId/messages').replace(queryParameters: qp);

    final res = await _client.get(uri, headers: _headers());
    _throwIfBad(res);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['messages'] as List<dynamic>? ?? []);
  }

  Future<Map<String, dynamic>> sendMessage(String conversationId, String text) async {
    final res = await _client.post(
      _url('/conversations/$conversationId/messages'),
      headers: _headers(),
      body: jsonEncode({'text': text}),
    );
    _throwIfBad(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
