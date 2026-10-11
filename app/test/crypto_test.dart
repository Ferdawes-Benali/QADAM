import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:qadam_app/services/crypto_service.dart';

String hex(List<int> b) => b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

void main() {
  // RFC 7914 §11 / well-known PBKDF2-HMAC-SHA256 vectors
  test('PBKDF2-HMAC-SHA256, 1 iteration', () {
    expect(hex(CryptoService.pbkdf2('password', utf8.encode('salt'), rounds: 1)),
        '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b');
  });
  test('PBKDF2-HMAC-SHA256, 2 iterations', () {
    expect(hex(CryptoService.pbkdf2('password', utf8.encode('salt'), rounds: 2)),
        'ae4d0c95af6b46d32d0adff928f06dd02a303f8ef3c251dfd6e2d85a95474c43');
  });
  test('key is 32 bytes (AES-256) and verifier depends on the key', () {
    final a = CryptoService.pbkdf2('1234', utf8.encode('salt-salt-salt-1'), rounds: 10);
    final b = CryptoService.pbkdf2('1235', utf8.encode('salt-salt-salt-1'), rounds: 10);
    expect(a.length, 32);
    expect(CryptoService.verifier(a), isNot(CryptoService.verifier(b)));
  });
}
