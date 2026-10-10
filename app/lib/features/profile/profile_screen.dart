import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/strings.dart';
import '../../services/gemini_service.dart';
import '../../services/report_service.dart';
import '../../services/storage_service.dart';
import '../../state/app_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final t = s.t;
    final p = s.profile!;
    return ListView(children: [
      Padding(padding: const EdgeInsets.all(20), child: Text(t(K.me), style: Theme.of(context).textTheme.headlineSmall)),
      Card(child: ListTile(
        leading: const Icon(Icons.person_rounded),
        title: Text(p.name),
        subtitle: Text('Diabète ${p.diabetesType} · risque pied: ${p.footRisk} · ${p.treatment}'),
      )),
      Card(child: Column(children: [
        ListTile(
          leading: const Icon(Icons.translate),
          title: Text(t(K.language)),
          trailing: DropdownButton<String>(
            value: s.lang,
            items: const [
              DropdownMenuItem(value: 'aeb', child: Text('Derja')),
              DropdownMenuItem(value: 'ar', child: Text('العربية')),
              DropdownMenuItem(value: 'fr', child: Text('Français')),
            ],
            onChanged: (v) => s.setLang(v ?? 'aeb'),
          ),
        ),
        SwitchListTile(value: s.advancedMode, onChanged: s.setAdvanced, title: const Text('Mode avancé / وضع متقدم')),
        SwitchListTile(value: s.demoMode, onChanged: s.setDemo, title: Text(t(K.demoMode))),
      ])),
      Card(child: ListTile(
        leading: const Icon(Icons.picture_as_pdf_rounded),
        title: Text(t(K.report)),
        onTap: () async {
          final summary = await GeminiService().doctorSummary(p, s.glucose, s.scans, s.adherencePct(days: 30));
          await ReportService.shareReport(profile: p, glucose: s.glucose, scans: s.scans,
              medsAdherencePct: s.adherencePct(days: 30), aiSummary: summary);
        },
      )),
      Card(child: ListTile(
        leading: const Icon(Icons.restart_alt_rounded),
        title: const Text('Réinitialiser la démo (scans)'),
        onTap: () async {
          await StorageService.clear('scans');
          await s.load();
        },
      )),
      Padding(padding: const EdgeInsets.all(20), child: Text(t(K.disclaimer), style: Theme.of(context).textTheme.bodySmall)),
    ]);
  }
}
