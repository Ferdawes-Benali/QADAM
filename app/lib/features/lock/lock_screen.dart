import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/tokens.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});
  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final pin = TextEditingController();
  bool busy = false;
  String? error;
  int failures = 0;

  @override
  void dispose() {
    pin.dispose();
    super.dispose();
  }

  Future<void> _unlock(AppState s) async {
    if (pin.text.length < 4 || busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    final ok = await s.unlock(pin.text);
    if (!mounted) return;
    if (!ok) {
      failures++;
      pin.clear();
      setState(() {
        busy = false;
        error = s.t('lock.wrong');
      });
      if (failures >= 5) {
        setState(() => busy = true);
        await Future<void>.delayed(const Duration(seconds: 30)); // slows down guessing
        if (mounted) setState(() => busy = false);
      }
    }
  }

  Future<void> _reset(AppState s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(s.t('lock.reset.title')),
        content: Text(s.t('lock.reset.body')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(s.t('common.cancel'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: QColors.alert),
            onPressed: () => Navigator.pop(c, true),
            child: Text(s.t('lock.reset.confirm')),
          ),
        ],
      ),
    );
    if (ok == true) await s.eraseEverything(remote: false);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Center(child: BrandLogo(width: 170)),
              const SizedBox(height: 36),
              Text(s.t('lock.title'), textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(s.t('lock.sub'), textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 24),
              TextField(
                controller: pin,
                autofocus: true,
                obscureText: true,
                enabled: !busy,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, letterSpacing: 14, fontWeight: FontWeight.w600),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                decoration: InputDecoration(labelText: s.t('pin.enter')),
                onSubmitted: (_) => _unlock(s),
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                InfoBanner(error!, tone: BannerTone.alert, icon: Icons.error_outline_rounded),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: busy ? null : () => _unlock(s),
                child: busy
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : Text(s.t('lock.unlock')),
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: busy ? null : () => _reset(s), child: Text(s.t('lock.forgot'))),
              const SizedBox(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (final l in const [('aeb', 'تونسي'), ('ar', 'العربية'), ('fr', 'FR')])
                  TextButton(
                    onPressed: () => s.setLang(l.$1),
                    child: Text(l.$2, style: TextStyle(fontWeight: s.lang == l.$1 ? FontWeight.w700 : FontWeight.w400)),
                  ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}
