import 'package:hive_flutter/hive_flutter.dart';

/// Local-first storage (works offline, no account needed for the demo).
/// Everything is stored as plain Maps in Hive boxes.
class StorageService {
  static late Box _settings, _glucose, _meds, _scans;

  static Future<void> init() async {
    await Hive.initFlutter();
    _settings = await Hive.openBox('settings');
    _glucose = await Hive.openBox('glucose');
    _meds = await Hive.openBox('meds');
    _scans = await Hive.openBox('scans');
  }

  static T? get<T>(String key) => _settings.get(key) as T?;
  static Future<void> set(String key, dynamic value) => _settings.put(key, value);

  static List<Map> all(String box) => _box(box).values.cast<Map>().toList();
  static Future<void> add(String box, Map value) => _box(box).add(value);
  static Future<void> put(String box, String key, Map value) => _box(box).put(key, value);
  static Future<void> clear(String box) => _box(box).clear();

  static Box _box(String name) => switch (name) {
        'glucose' => _glucose,
        'meds' => _meds,
        'scans' => _scans,
        _ => _settings,
      };
}
