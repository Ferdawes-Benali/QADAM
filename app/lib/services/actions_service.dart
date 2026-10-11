import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';

/// Phone calls, WhatsApp pre-filled messages (the patient presses "send": nothing is sent automatically)
/// and the Derja voice clips recorded by a native speaker (assets/audio/*.mp3, optional).
class ActionsService {
  static final _player = AudioPlayer();

  static String _digits(String phone) => phone.replaceAll(RegExp(r'[^0-9]'), '');

  static Future<bool> whatsapp(String phone, String message) => launchUrl(
        Uri.parse('https://wa.me/${_digits(phone)}?text=${Uri.encodeComponent(message)}'),
        mode: LaunchMode.externalApplication,
      );

  static Future<bool> call(String phone) => launchUrl(Uri.parse('tel:+${_digits(phone)}'));

  static Future<bool> callEmergency() => launchUrl(Uri.parse('tel:190'));

  /// foot_green, foot_amber, foot_red, sugar_low — silently skipped if the clip was not recorded yet.
  static Future<void> playClip(String name) async {
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/$name.mp3'));
    } catch (_) {
      // clip missing: the screen already shows the message in text
    }
  }
}
