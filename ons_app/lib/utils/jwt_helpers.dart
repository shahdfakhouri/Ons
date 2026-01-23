import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:ons_app/services/auth_service.dart';

int? getLoggedInIdFromJwt() {
  final token = AuthService().token;
  if (token == null || token.isEmpty) return null;

  final decoded = JwtDecoder.decode(token);
  final id = decoded['id'];
  if (id == null) return null;

  return int.tryParse(id.toString());
}
