import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Client for the care team's Qadam Hub (hub/). The hub holds the AI key; the app never does.
class HubException implements Exception {
  final int status;
  final String message;
  HubException(this.status, this.message);
  @override
  String toString() => message;
}

class HubService {
  final String baseUrl; // e.g. http://192.168.43.10:8000
  final String? token;
  HubService(String url, {this.token}) : baseUrl = url.trim().replaceAll(RegExp(r'/+$'), '');

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<dynamic> _send(String method, String path, {Object? body, Duration timeout = const Duration(seconds: 8)}) async {
    final uri = Uri.parse('$baseUrl$path');
    http.Response r;
    try {
      r = switch (method) {
        'GET' => await http.get(uri, headers: _headers).timeout(timeout),
        'DELETE' => await http.delete(uri, headers: _headers).timeout(timeout),
        _ => await http.post(uri, headers: _headers, body: jsonEncode(body ?? {})).timeout(timeout),
      };
    } on TimeoutException {
      throw HubException(0, 'timeout');
    } catch (_) {
      throw HubException(0, 'unreachable');
    }
    dynamic data;
    try {
      data = jsonDecode(utf8.decode(r.bodyBytes));
    } catch (_) {
      data = null;
    }
    if (r.statusCode >= 400) {
      final detail = data is Map && data['detail'] != null ? data['detail'].toString() : 'HTTP ${r.statusCode}';
      throw HubException(r.statusCode, detail);
    }
    return data;
  }

  Future<Map<String, dynamic>> health() async => Map<String, dynamic>.from(await _send('GET', '/api/health') as Map);

  Future<Map<String, dynamic>> pair(String code, {required bool share, required bool ai, String? diabetesType, String? footRisk}) async =>
      Map<String, dynamic>.from(await _send('POST', '/api/patient/pair', body: {
        'code': code.trim(),
        'share_with_care_team': share,
        'ai_assistant': ai,
        if (diabetesType != null) 'diabetes_type': diabetesType,
        if (footRisk != null) 'foot_risk': footRisk,
      }) as Map);

  Future<Map<String, dynamic>> sync(List<Map<String, dynamic>> items) async =>
      Map<String, dynamic>.from(await _send('POST', '/api/patient/sync', body: {'items': items}) as Map);

  Future<List<Map<String, dynamic>>> alerts() async =>
      [for (final a in (await _send('GET', '/api/patient/alerts') as List)) Map<String, dynamic>.from(a as Map)];

  Future<Map<String, dynamic>> ask(String question, String lang, Map<String, dynamic>? context) async =>
      Map<String, dynamic>.from(await _send('POST', '/api/patient/assistant',
          body: {'question': question, 'lang': lang, 'context': context}, timeout: const Duration(seconds: 25)) as Map);

  Future<void> eraseRemote() async => _send('DELETE', '/api/patient/data');
}
