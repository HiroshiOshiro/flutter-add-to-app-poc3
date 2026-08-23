import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:legacyapp_flutter/data/services/api_client.dart';

void main() {
  test('postJson sends the body as JSON and accepts 2xx', () async {
    late http.Request captured;
    final ApiClient client = ApiClient(
      httpClient: MockClient((http.Request request) async {
        captured = request;
        return http.Response('{}', 201);
      }),
    );

    final bool ok = await client.postJson(
      Uri.parse('https://example.com/posts'),
      <String, Object?>{'name': '山田'},
    );

    expect(ok, isTrue);
    expect(captured.method, 'POST');
    expect(jsonDecode(captured.body), <String, Object?>{'name': '山田'});
    expect(captured.headers['Content-Type'], contains('application/json'));
  });

  test('postJson reports a non-2xx response as a failure', () async {
    final ApiClient client = ApiClient(
      httpClient: MockClient((_) async => http.Response('error', 500)),
    );

    expect(
      await client.postJson(Uri.parse('https://example.com/posts'), const {}),
      isFalse,
    );
  });
}
