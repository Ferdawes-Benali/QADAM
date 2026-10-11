import 'dart:convert';
import 'dart:isolate';

import 'package:hive_flutter/hive_flutter.dart';

import 'crypto_service.dart';

/// Local-first storage. Health data lives in Hive boxes encrypted with AES-256 (HiveAesCipher),
/// key derived from the patient's PIN. Only non-sensitive metadata (salt, verifier, language) is in clear.
class StorageService {
  static const _dataBoxes = ['settings', 'glucose', 'meds', 'scans', 'outbox', 'hubalerts'];
  static late Box _meta;
  static final Map<String, Box> _boxes = {};

  static bool get isUnlocked => _boxes.length == _dataBoxes.length;

  static Future<void> init() async {
    await Hive.initFlutter();
    _meta = await Hive.openBox('meta');
  }

  // ---------- meta (clear) ----------
  static bool get hasPin => _meta.get('salt') != null;
  static String? get metaLang => _meta.get('lang') as String?;
  static Future<void> setMetaLang(String v) => _meta.put('lang', v);

  /// First run: create salt + verifier and open the encrypted boxes.
  /// PBKDF2 runs in a background isolate so the UI keeps animating.
  static Future<List<int>> _derive(String pin, List<int> salt) => Isolate.run(() => CryptoService.pbkdf2(pin, salt));

  static Future<void> createPin(String pin) async {
    final salt = CryptoService.randomBytes(16);
    final key = await _derive(pin, salt);
    await _meta.put('salt', base64Encode(salt));
    await _meta.put('verifier', CryptoService.verifier(key));
    await _open(key);
  }

  /// Returns false on a wrong PIN (nothing is opened).
  static Future<bool> unlock(String pin) async {
    final salt = base64Decode(_meta.get('salt') as String);
    final key = await _derive(pin, salt);
    if (CryptoService.verifier(key) != _meta.get('verifier')) return false;
    await _open(key);
    return true;
  }

  /// Re-encrypts every box with a key derived from the new PIN.
  static Future<bool> changePin(String oldPin, String newPin) async {
    final salt = base64Decode(_meta.get('salt') as String);
    if (CryptoService.verifier(await _derive(oldPin, salt)) != _meta.get('verifier')) return false;
    final snapshot = <String, Map<dynamic, dynamic>>{
      for (final n in _dataBoxes) n: Map<dynamic, dynamic>.from(_boxes[n]!.toMap()),
    };
    await lock();
    for (final n in _dataBoxes) {
      await Hive.deleteBoxFromDisk(n);
    }
    await createPin(newPin);
    for (final e in snapshot.entries) {
      await _boxes[e.key]!.putAll(e.value);
    }
    return true;
  }

  static Future<void> _open(List<int> key) async {
    final cipher = HiveAesCipher(key);
    for (final n in _dataBoxes) {
      _boxes[n] = await Hive.openBox(n, encryptionCipher: cipher);
    }
  }

  static Future<void> lock() async {
    for (final b in _boxes.values) {
      await b.close();
    }
    _boxes.clear();
  }

  /// Right to erasure: deletes every local box, including the PIN material.
  static Future<void> eraseEverything() async {
    await lock();
    for (final n in _dataBoxes) {
      await Hive.deleteBoxFromDisk(n);
    }
    await _meta.clear();
  }

  // ---------- data (encrypted) ----------
  static T? get<T>(String key) => _boxes['settings']?.get(key) as T?;
  static Future<void> set(String key, dynamic value) async => _boxes['settings']?.put(key, value);
  static Future<void> remove(String key) async => _boxes['settings']?.delete(key);

  static List<Map> all(String box) => (_boxes[box]?.values ?? const []).whereType<Map>().toList();
  static Future<void> put(String box, String key, Map value) async => _boxes[box]?.put(key, value);
  static Future<void> delete(String box, String key) async => _boxes[box]?.delete(key);
  static Future<void> clear(String box) async => _boxes[box]?.clear();
  static Map<String, dynamic> exportAll() => {
        for (final n in _dataBoxes) n: _boxes[n]?.toMap().map((k, v) => MapEntry(k.toString(), v)) ?? {},
      };
}
