import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/tokens.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';

/// 7 short steps: language -> what Qadam does -> consent -> about you -> feet risk -> contacts -> PIN.
/// Nothing is written to disk before the PIN exists (the PIN derives the encryption key).
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});
  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  int step = 0;
  static const steps = 7;

  // consent
  bool understood = false, share = true, ai = true;
  // profile
  final name = TextEditingController();
  final year = TextEditingController();
  String type = 't2', treatment = 'tablets';
  bool? ulcer, numb;
  final docName = TextEditingController(), docPhone = TextEditingController();
  final famName = TextEditingController(), famPhone = TextEditingController();
  // pin
  final pin1 = TextEditingController(), pin2 = TextEditingController();
  String? pinError;
  bool saving = false;

  @override
  void dispose() {
    for (final c in [name, year, docName, docPhone, famName, famPhone, pin1, pin2]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get canNext => switch (step) {
        2 => understood,
        3 => name.text.trim().isNotEmpty,
        4 => ulcer != null && numb != null,
        _ => true,
      };

  Future<void> _finish(AppState s) async {
    final a = pin1.text.trim(), b = pin2.text.trim();
    if (a.length < 4 || a.length > 6 || int.tryParse(a) == null) {
      setState(() => pinError = s.t('pin.err.format'));
      return;
    }
    if (a != b) {
      setState(() => pinError = s.t('pin.err.match'));
      return;
    }
    setState(() {
      pinError = null;
      saving = true;
    });
    final p = Profile(
      name: name.text.trim(),
      diabetesType: type,
      treatment: treatment,
      yearDiagnosed: int.tryParse(year.text.trim()),
      pastUlcer: ulcer ?? false,
      numbness: numb ?? false,
      doctorName: docName.text.trim(),
      doctorPhone: docPhone.text.trim(),
      familyName: famName.text.trim(),
      familyPhone: famPhone.text.trim(),
    );
    await s.completeOnboarding(p, a, share: share, ai: ai);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final t = s.t;
    final body = switch (step) {
      0 => _language(s),
      1 => _about(s),
      2 => _consent(s),
      3 => _you(s),
      4 => _risk(s),
      5 => _contacts(s),
      _ => _pin(s),
    };
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          if (step > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
              child: Row(children: [
                IconButton(
                  tooltip: t('common.back'),
                  icon: const BackButtonIcon(),
                  onPressed: saving ? null : () => setState(() => step--),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: step / (steps - 1),
                      minHeight: 6,
                      backgroundColor: QColors.sky100,
                      color: QColors.navy700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text('${step + 1}/$steps', style: Theme.of(context).textTheme.bodySmall),
              ]),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: body,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: saving || !canNext
                    ? null
                    : () {
                        if (step == steps - 1) {
                          _finish(s);
                        } else {
                          setState(() => step++);
                        }
                      },
                child: saving
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : Text(step == 0 ? t('onb.start') : (step == steps - 1 ? t('onb.finish') : t('common.next'))),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _h(String title, [String? sub]) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        if (sub != null) ...[const SizedBox(height: 8), Text(sub, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: QColors.ink2))],
        const SizedBox(height: 24),
      ]);

  Widget _language(AppState s) {
    Widget option(String code, String label, String sample) {
      final on = s.lang == code;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: on ? QColors.sky100 : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(QRadius.md),
            side: BorderSide(color: on ? QColors.navy700 : QColors.lineStrong, width: on ? 2 : 1),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(QRadius.md),
            onTap: () => s.setLang(code),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(label, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: QColors.ink)),
                    Text(sample, style: const TextStyle(fontSize: 14, color: QColors.ink2)),
                  ]),
                ),
                Icon(on ? Icons.check_circle_rounded : Icons.circle_outlined, color: on ? QColors.navy700 : QColors.lineStrong),
              ]),
            ),
          ),
        ),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 24),
      const Center(child: BrandLogo(width: 210)),
      const SizedBox(height: 28),
      Text(s.t('onb.tagline'), style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.start),
      const SizedBox(height: 8),
      Text(s.t('onb.taglineSub'), style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: QColors.ink2)),
      const SizedBox(height: 28),
      Text(s.t('onb.chooseLang'), style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 12),
      option('aeb', 'تونسي — Derja', 'عسلامة، قدم يعاونك'),
      option('ar', 'العربية', 'مرحبا، قدم يساعدك'),
      option('fr', 'Français', 'Bonjour, Qadam vous accompagne'),
    ]);
  }

  Widget _about(AppState s) {
    Widget point(IconData i, String title, String body) => Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: QColors.sky100, borderRadius: BorderRadius.circular(12)),
              child: Icon(i, color: QColors.navy700),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(body, style: Theme.of(context).textTheme.bodyMedium),
              ]),
            ),
          ]),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _h(s.t('onb.about.title')),
      point(Icons.thermostat_rounded, s.t('onb.about.p1.t'), s.t('onb.about.p1.b')),
      point(Icons.water_drop_outlined, s.t('onb.about.p2.t'), s.t('onb.about.p2.b')),
      point(Icons.people_alt_outlined, s.t('onb.about.p3.t'), s.t('onb.about.p3.b')),
      InfoBanner(s.t('common.notDiagnosis'), icon: Icons.health_and_safety_outlined),
    ]);
  }

  Widget _consent(AppState s) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _h(s.t('consent.title'), s.t('consent.sub')),
        _consentRow(Icons.lock_outline_rounded, s.t('consent.local.t'), s.t('consent.local.b'), null, null),
        _consentRow(Icons.local_hospital_outlined, s.t('consent.share.t'), s.t('consent.share.b'), share,
            (v) => setState(() => share = v)),
        _consentRow(Icons.auto_awesome_outlined, s.t('consent.ai.t'), s.t('consent.ai.b'), ai, (v) => setState(() => ai = v)),
        const SizedBox(height: 8),
        CheckboxListTile(
          value: understood,
          onChanged: (v) => setState(() => understood = v ?? false),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(s.t('consent.understand'), style: Theme.of(context).textTheme.bodyLarge),
        ),
        Text(s.t('consent.change'), style: Theme.of(context).textTheme.bodySmall),
      ]);

  Widget _consentRow(IconData icon, String title, String body, bool? value, ValueChanged<bool>? onChanged) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SectionCard(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: QColors.navy700),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(body, style: Theme.of(context).textTheme.bodyMedium),
              ]),
            ),
            if (value != null) Switch(value: value, onChanged: onChanged),
          ]),
        ),
      );

  Widget _chips(List<(String, String)> options, String selected, ValueChanged<String> onSelect) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final o in options)
            ChoiceChip(
              label: Text(o.$2),
              selected: selected == o.$1,
              onSelected: (_) => onSelect(o.$1),
              showCheckmark: false,
              labelStyle: TextStyle(
                fontWeight: selected == o.$1 ? FontWeight.w600 : FontWeight.w400,
                color: selected == o.$1 ? QColors.navy900 : QColors.ink2,
              ),
              side: BorderSide(color: selected == o.$1 ? QColors.navy700 : QColors.lineStrong),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            ),
        ],
      );

  Widget _you(AppState s) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _h(s.t('you.title'), s.t('you.sub')),
        TextField(
          controller: name,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: s.t('you.name'), helperText: s.t('you.nameHelp')),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 20),
        Text(s.t('you.type'), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        _chips([('t1', s.t('type.t1')), ('t2', s.t('type.t2')), ('gest', s.t('type.gest')), ('other', s.t('type.other'))],
            type, (v) => setState(() => type = v)),
        const SizedBox(height: 20),
        Text(s.t('you.treatment'), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        _chips([
          ('tablets', s.t('treat.tablets')),
          ('insulin', s.t('treat.insulin')),
          ('both', s.t('treat.both')),
          ('diet', s.t('treat.diet')),
        ], treatment, (v) => setState(() => treatment = v)),
        const SizedBox(height: 20),
        TextField(
          controller: year,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
          decoration: InputDecoration(labelText: s.t('you.year')),
        ),
      ]);

  Widget _risk(AppState s) {
    Widget q(String text, bool? value, ValueChanged<bool> set) => Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(text, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            _chips([('yes', s.t('common.yes')), ('no', s.t('common.no'))], value == null ? '' : (value ? 'yes' : 'no'),
                (v) => set(v == 'yes')),
          ]),
        );
    final risk = (ulcer ?? false) ? 'high' : ((numb ?? false) ? 'moderate' : 'low');
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _h(s.t('risk.title'), s.t('risk.sub')),
      q(s.t('risk.q1'), ulcer, (v) => setState(() => ulcer = v)),
      q(s.t('risk.q2'), numb, (v) => setState(() => numb = v)),
      if (ulcer != null && numb != null)
        InfoBanner(s.t('risk.result.$risk'),
            icon: Icons.directions_walk_rounded, tone: risk == 'high' ? BannerTone.warn : BannerTone.info),
    ]);
  }

  Widget _contacts(AppState s) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _h(s.t('contacts.title'), s.t('contacts.sub')),
        Text(s.t('contacts.doctor'), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        TextField(controller: docName, decoration: InputDecoration(labelText: s.t('contacts.name'))),
        const SizedBox(height: 10),
        TextField(
          controller: docPhone,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(labelText: s.t('contacts.phone'), hintText: '216 71 000 000'),
        ),
        const SizedBox(height: 24),
        Text(s.t('contacts.family'), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        TextField(controller: famName, decoration: InputDecoration(labelText: s.t('contacts.name'))),
        const SizedBox(height: 10),
        TextField(
          controller: famPhone,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(labelText: s.t('contacts.phone'), hintText: '216 98 000 000'),
        ),
        const SizedBox(height: 12),
        Text(s.t('contacts.skip'), style: Theme.of(context).textTheme.bodySmall),
      ]);

  Widget _pin(AppState s) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _h(s.t('pin.title'), s.t('pin.sub')),
        _pinField(pin1, s.t('pin.enter')),
        const SizedBox(height: 14),
        _pinField(pin2, s.t('pin.confirm')),
        if (pinError != null) ...[
          const SizedBox(height: 12),
          InfoBanner(pinError!, tone: BannerTone.alert, icon: Icons.error_outline_rounded),
        ],
        const SizedBox(height: 16),
        InfoBanner(s.t('pin.warning'), icon: Icons.key_rounded, tone: BannerTone.warn),
      ]);

  Widget _pinField(TextEditingController c, String label) => TextField(
        controller: c,
        obscureText: true,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 26, letterSpacing: 12, fontWeight: FontWeight.w600),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
        decoration: InputDecoration(labelText: label),
      );
}
