import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ons_app/core/constants/api_config.dart';

class ElderAuthService {
  static final ElderAuthService _i = ElderAuthService._internal();
  factory ElderAuthService() => _i;
  ElderAuthService._internal();

  static const _elderTokenKey = 'elder_token';
  static const _elderIdKey = 'elder_id';

  String? _token;
  int? _elderId;

  String? get token => _token;
  int? get elderId => _elderId;

  Future<void> loadSession() async {
    final sp = await SharedPreferences.getInstance();
    _token = sp.getString(_elderTokenKey);
    _elderId = sp.getInt(_elderIdKey);
  }

  Future<void> logout() async {
    _token = null;
    _elderId = null;
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_elderTokenKey);
    await sp.remove(_elderIdKey);
  }

  Future<bool> pinLogin({required int elderId, required String pin}) async {
    final url = Uri.parse('${ApiConfig.elderBase}/auth/pin-login');

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'elder_id': elderId, 'pin': pin}),
    );

    if (res.statusCode != 200) return false;

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final token = data['token']?.toString();
    if (token == null || token.isEmpty) return false;

    _token = token;
    _elderId = elderId;

    final sp = await SharedPreferences.getInstance();
    await sp.setString(_elderTokenKey, token);
    await sp.setInt(_elderIdKey, elderId);
    return true;
  }
}
