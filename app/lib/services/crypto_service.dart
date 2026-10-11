import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Derives the AES-256 key that encrypts the local Hive boxes from the patient's PIN.
/// PBKDF2-HMAC-SHA256 (RFC 8018). The PIN itself is never stored: only a salt and a verifier hash.
/// Prototype choice: production would keep a random key in the Android Keystore and use the PIN/biometrics to unlock it.
class CryptoService {
  static const iterations = 20000;

  static Uint8List randomBytes(int n) {
    final r = Random.secure();
    return Uint8List.fromList(List<int>.generate(n, (_) => r.nextInt(256)));
  }

  static Uint8List pbkdf2(String password, List<int> salt, {int rounds = iterations, int length = 32}) {
    final hmac = Hmac(sha256, utf8.encode(password));
    final out = BytesBuilder();
    var block = 1;
    while (out.length < length) {
      final blockIndex = Uint8List(4)..buffer.asByteData().setUint32(0, block);
      var u = hmac.convert([...salt, ...blockIndex]).bytes;
      final t = List<int>.from(u);
      for (var i = 1; i < rounds; i++) {
        u = hmac.convert(u).bytes;
        for (var j = 0; j < t.length; j++) {
          t[j] ^= u[j];
        }
      }
      out.add(t);
      block++;
    }
    return Uint8List.fromList(out.toBytes().sublist(0, length));
  }

  /// Verifier stored next to the salt: lets us reject a wrong PIN before trying to open encrypted boxes.
  static String verifier(List<int> key) => sha256.convert([...key, ...utf8.encode('qadam-pin-verifier')]).toString();
}
