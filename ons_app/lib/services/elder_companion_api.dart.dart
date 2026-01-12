import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:ons_app/core/constants/api_config.dart';
import 'package:ons_app/services/elder_auth_service.dart';

class CompanionService {
  Future<Map<String, dynamic>> chat({
    required String message,
    String? conversationId,
  }) async {
    final elderId = ElderAuthService().elderId;
    if (elderId == null) {
      throw Exception('elderId is null (not logged in as elder)');
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/api/companion/chat');

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'elderId': elderId,
        'message': message,
        if (conversationId != null && conversationId.isNotEmpty) 'conversationId': conversationId,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Companion failed: ${res.statusCode} ${res.body}');
    }

    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
