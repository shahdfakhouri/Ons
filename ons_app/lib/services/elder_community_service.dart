import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ons_app/core/constants/api_config.dart';
import 'package:ons_app/services/elder_auth_service.dart';

class ElderCommunityService {
  static final ElderCommunityService _i = ElderCommunityService._internal();
  factory ElderCommunityService() => _i;
  ElderCommunityService._internal();

  String get _base => ApiConfig.communityBase;

  Map<String, String> _headers() {
    final token = ElderAuthService().token;
    if (token == null || token.isEmpty) {
      throw Exception('Elder not logged in (missing token)');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<Map<String, dynamic>>> getPosts({String? category}) async {
    final uri = Uri.parse('$_base/posts').replace(
      queryParameters: {
        if (category != null && category.isNotEmpty) 'category': category,
      },
    );

    final res = await http.get(uri, headers: _headers());
    if (res.statusCode != 200) {
      throw Exception('Failed to load posts: ${res.statusCode} ${res.body}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final posts = (data['posts'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    return posts;
  }

  Future<Map<String, dynamic>> getPostById(int postId) async {
    final uri = Uri.parse('$_base/posts/$postId');
    final res = await http.get(uri, headers: _headers());
    if (res.statusCode != 200) {
      throw Exception('Failed to load post: ${res.statusCode} ${res.body}');
    }
    return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
  }

  Future<int> createPost({
    required String title,
    required String content,
    String? category,
  }) async {
    final uri = Uri.parse('$_base/posts');
    final res = await http.post(
      uri,
      headers: _headers(),
      body: jsonEncode({
        'title': title.trim(),
        'content': content.trim(),
        if (category != null && category.trim().isNotEmpty) 'category': category.trim(),
      }),
    );

    if (res.statusCode != 201) {
      throw Exception('Failed to create post: ${res.statusCode} ${res.body}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['post_id'] as num).toInt();
  }

  Future<void> addComment({
    required int postId,
    required String text,
  }) async {
    final uri = Uri.parse('$_base/posts/$postId/comments');
    final res = await http.post(
      uri,
      headers: _headers(),
      body: jsonEncode({'content': text.trim()}),
    );
    if (res.statusCode != 201) {
      throw Exception('Failed to add comment: ${res.statusCode} ${res.body}');
    }
  }

  Future<void> reportPost({required int postId, String? reason}) async {
    final uri = Uri.parse('$_base/posts/$postId/report');
    final res = await http.post(
      uri,
      headers: _headers(),
      body: jsonEncode({'reason': reason}),
    );
    if (res.statusCode != 201) {
      throw Exception('Failed to report post: ${res.statusCode} ${res.body}');
    }
  }

  Future<void> reportComment({required int commentId, String? reason}) async {
    final uri = Uri.parse('$_base/comments/$commentId/report');
    final res = await http.post(
      uri,
      headers: _headers(),
      body: jsonEncode({'reason': reason}),
    );
    if (res.statusCode != 201) {
      throw Exception('Failed to report comment: ${res.statusCode} ${res.body}');
    }
  }

  Future<void> deletePost(int postId) async {
    final uri = Uri.parse('$_base/posts/$postId');
    final res = await http.delete(uri, headers: _headers());
    if (res.statusCode != 200) {
      throw Exception('Failed to delete post: ${res.statusCode} ${res.body}');
    }
  }

  Future<void> deleteComment(int commentId) async {
    final uri = Uri.parse('$_base/comments/$commentId');
    final res = await http.delete(uri, headers: _headers());
    if (res.statusCode != 200) {
      throw Exception('Failed to delete comment: ${res.statusCode} ${res.body}');
    }
  }
}
