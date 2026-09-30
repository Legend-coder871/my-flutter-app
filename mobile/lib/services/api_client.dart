import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:mobile/config.dart';

// Thrown whenever the API returns an error or the server cannot be reached.
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

// Small HTTP client for the backend REST API.
class ApiClient {
  static const Duration _timeout = Duration(seconds: 10);

  Future<dynamic> get(String path, {String? token}) {
    return _send('GET', path, null, token);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body, String? token}) {
    return _send('POST', path, body, token);
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body, String? token}) {
    return _send('PUT', path, body, token);
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? body, String? token}) {
    return _send('PATCH', path, body, token);
  }

  Future<dynamic> delete(String path, {Map<String, dynamic>? body, String? token}) {
    return _send('DELETE', path, body, token);
  }

  // Send one JSON request and decode the JSON response.
  Future<dynamic> _send(
    String method,
    String path,
    Map<String, dynamic>? body,
    String? token,
  ) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    http.Response response;
    try {
      final request = http.Request(method, uri)
        ..headers.addAll(headers)
        ..body = body == null ? '' : jsonEncode(body);
      final streamed = await request.send().timeout(_timeout);
      response = await http.Response.fromStream(streamed);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Cannot reach the server. Is the backend running?');
    }

    dynamic data;
    try {
      data = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      data = null;
    }

    if (response.statusCode >= 400) {
      if (data is Map && data['error'] is String) {
        throw ApiException(data['error'] as String);
      }
      throw ApiException('Request failed with status ${response.statusCode}');
    }
    return data;
  }
}
