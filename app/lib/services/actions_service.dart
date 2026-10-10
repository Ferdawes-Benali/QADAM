import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';

/// WhatsApp, phone calls and Derja voice clips.
class ActionsService {
  static final _player = AudioPlayer();

  /// Opens WhatsApp with a pre-filled message; the patient taps "send" (no API needed).
  /// phone: international format without '+', e.g. 21698123456.
  static Future<void> whatsapp(String phone, String message) async {
    final uri = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(message)}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<void> call(String phone) => launchUrl(Uri.parse('tel:+$phone'));

  /// Clips recorded by a native speaker: assets/audio/foot_green.mp3, foot_amber.mp3, foot_red.mp3, sugar_low.mp3
  static Future<void> playClip(String name) async {
    try {
      await _player.play(AssetSource('audio/$name.mp3'));
    } catch (_) {/* clip missing during development */}
  }
}
