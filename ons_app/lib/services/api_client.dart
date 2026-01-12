import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'package:ons_app/core/constants/api_config.dart';
import 'package:ons_app/services/auth_service.dart';

class ApiClient {
  final String _baseUrl = ApiConfig.apiBase;

  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: query);
    return _send(() => http.get(uri, headers: _headers()));
  }

  Future<dynamic> post(String path, {Object? body}) async {
    final uri = Uri.parse('$_baseUrl$path');
    return _send(() => http.post(uri, headers: _headers(), body: jsonEncode(body ?? {})));
  }

  Future<dynamic> put(String path, {Object? body}) async {
    final uri = Uri.parse('$_baseUrl$path');
    return _send(() => http.put(uri, headers: _headers(), body: jsonEncode(body ?? {})));
  }

  Future<dynamic> patch(String path, {Object? body}) async {
    final uri = Uri.parse('$_baseUrl$path');
    return _send(() => http.patch(uri, headers: _headers(), body: jsonEncode(body ?? {})));
  }

  Future<dynamic> delete(String path) async {
    final uri = Uri.parse('$_baseUrl$path');
    return _send(() => http.delete(uri, headers: _headers()));
  }

  /// ✅ Multipart upload for /elder/gallery/upload
  Future<dynamic> uploadFile(
    String path, {
    required File file,
    String fieldName = "file",
    Map<String, String>? fields,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');

    final req = http.MultipartRequest("POST", uri);
    req.headers.addAll(_headers(isJson: false));
    if (fields != null) req.fields.addAll(fields);

    req.files.add(await http.MultipartFile.fromPath(fieldName, file.path));

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    return _decodeOrThrow(res);
  }

  Map<String, String> _headers({bool isJson = true}) {
    final token = AuthService().token;
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    if (isJson) headers['Content-Type'] = 'application/json';
    if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  Future<dynamic> _send(Future<http.Response> Function() call) async {
    final res = await call();
    return _decodeOrThrow(res);
  }

  dynamic _decodeOrThrow(http.Response res) {
    final dynamic decoded = res.body.isNotEmpty ? jsonDecode(res.body) : {};
    if (res.statusCode >= 200 && res.statusCode < 300) return decoded;

    final msg = (decoded is Map && decoded['msg'] != null)
        ? decoded['msg'].toString()
        : 'Request failed (${res.statusCode})';
    throw ApiException(res.statusCode, msg, decoded);
  }
}

class ApiException implements Exception {
  final int status;
  final String message;
  final dynamic payload;
  ApiException(this.status, this.message, this.payload);

  @override
  String toString() => 'ApiException($status): $message';
}
