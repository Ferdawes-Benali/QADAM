import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/diabetes_content.dart';
import '../../core/strings.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';

/// One-screen onboarding: language, profile, diabetes type (explained), foot history, contacts.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _name = TextEditingController();
  final _year = TextEditingController();
  final _doctor = TextEditingController();
  final _doctorPhone = TextEditingController();
  final _family = TextEditingController();
  final _familyPhone = TextEditingController();
  String _type = 't2', _treatment = 'tablets';
  bool _ulcer = false, _numb = false;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final t = s.t;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Qadam قدم', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(t(K.disclaimer)),
            const SizedBox(height: 20),
            Text(t(K.language), style: Theme.of(context).textTheme.titleMedium),
            Wrap(spacing: 8, children: [
              for (final l in const [('aeb', 'Derja'), ('ar', 'العربية'), ('fr', 'Français')])
                ChoiceChip(label: Text(l.$2), selected: s.lang == l.$1, onSelected: (_) => s.setLang(l.$1)),
            ]),
            const SizedBox(height: 16),
            TextField(controller: _name, decoration: InputDecoration(labelText: t(K.name))),
            const SizedBox(height: 16),
            Text(t(K.diabetesType), style: Theme.of(context).textTheme.titleMedium),
            Wrap(spacing: 8, children: [
              for (final d in const [('t1', 'Type 1'), ('t2', 'Type 2'), ('gest', 'Gestationnel'), ('other', 'Autre')])
                ChoiceChip(label: Text(d.$2), selected: _type == d.$1, onSelected: (_) => setState(() => _type = d.$1)),
            ]),
            Card(child: Padding(padding: const EdgeInsets.all(12), child: Text(diabetesTypeInfo[_type]!))),
            TextField(controller: _year, keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Année du diagnostic / سنة التشخيص')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _treatment,
              decoration: const InputDecoration(labelText: 'Traitement / العلاج'),
              items: const [
                DropdownMenuItem(value: 'insulin', child: Text('Insuline / أنسولين')),
                DropdownMenuItem(value: 'tablets', child: Text('Comprimés / حبوب')),
                DropdownMenuItem(value: 'diet', child: Text('Régime seul / حمية فقط')),
              ],
              onChanged: (v) => setState(() => _treatment = v ?? 'tablets'),
            ),
            SwitchListTile(value: _ulcer, onChanged: (v) => setState(() => _ulcer = v),
                title: const Text('Ancienne plaie au pied / جرح قديم في الساق')),
            SwitchListTile(value: _numb, onChanged: (v) => setState(() => _numb = v),
                title: const Text('Pieds engourdis / تنميل في الساقين')),
            TextField(controller: _doctor, decoration: const InputDecoration(labelText: 'Médecin / الطبيب')),
            TextField(controller: _doctorPhone, keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Tél. médecin (216...)')),
            TextField(controller: _family, decoration: const InputDecoration(labelText: 'Proche à prévenir / شكون نعلّمو')),
            TextField(controller: _familyPhone, keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'WhatsApp du proche (216...)')),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                if (_name.text.trim().isEmpty) return;
                s.saveProfile(Profile(
                  name: _name.text.trim(), diabetesType: _type, yearDiagnosed: int.tryParse(_year.text),
                  treatment: _treatment, pastUlcer: _ulcer, numbness: _numb,
                  doctorName: _doctor.text.trim(), doctorPhone: _doctorPhone.text.trim(),
                  familyName: _family.text.trim(), familyPhone: _familyPhone.text.trim(),
                ));
              },
              child: Text(t(K.save)),
            ),
          ],
        ),
      ),
    );
  }
}
