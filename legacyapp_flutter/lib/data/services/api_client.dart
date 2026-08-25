import 'dart:convert';

import 'package:http/http.dart' as http;

/// 通信の入口。
///
/// 方針により**API呼び出しはFlutter側で実装する**。ネイティブの通信基盤を
/// チャネル越しに呼ぶ形にすると、そのブリッジを全画面が使うことになり、
/// 全面移行の完了時にすべて捨てることになる。
class ApiClient {
  ApiClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;

  /// 共通ヘッダ。認証トークンなどが必要になったらここに集約する。
  Map<String, String> get _headers => const <String, String>{
    'Content-Type': 'application/json; charset=utf-8',
  };

  /// JSONをPOSTし、2xxが返ったかどうかを返す。
  Future<bool> postJson(Uri uri, Map<String, Object?> body) async {
    final http.Response response = await _http.post(
      uri,
      headers: _headers,
      body: jsonEncode(body),
    );
    return response.statusCode >= 200 && response.statusCode < 300;
  }
}
