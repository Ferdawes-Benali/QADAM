import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../services/actions_service.dart';
import '../../services/gemini_service.dart';
import '../../state/app_state.dart';
import '../../widgets/foot_status.dart';

/// Full-screen alert: status, AI explanation in the patient's language, family WhatsApp, call doctor.
class AlertScreen extends StatelessWidget {
  final FootScan scan;
  const AlertScreen({super.key, required this.scan});

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final t = s.t;
    final p = s.profile!;
    final color = QadamColors.forStatus(scan.status);
    return Scaffold(
      backgroundColor: color.withValues(alpha: 0.12),
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        FootStatusView(status: scan.status, hotSite: scan.site, size: 170),
        const SizedBox(height: 16),
        Text(t(scan.status == 'red' ? K.statusRed : K.statusAmber),
            textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: color)),
        Text('${t(K.difference)} : ${scan.maxDt.toStringAsFixed(1)} °C · ${scan.site}', textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FutureBuilder<String>(
              future: GeminiService().explainScan(scan, p, s.lang),
              builder: (_, snap) => snap.hasData
                  ? Text(snap.data!, style: const TextStyle(fontSize: 18))
                  : const LinearProgressIndicator(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (p.familyPhone.isNotEmpty)
          FilledButton.icon(
            icon: const Icon(Icons.chat_rounded),
            label: Text('${t(K.tellFamily)} (${p.familyName})'),
            onPressed: () => ActionsService.whatsapp(
              p.familyPhone,
              'Qadam: alerte pied pour ${p.name} (écart ${scan.maxDt.toStringAsFixed(1)} °C, ${scan.site}). '
              'Merci de l\'appeler et de vérifier son pied.',
            ),
          ),
        const SizedBox(height: 8),
        if (p.doctorPhone.isNotEmpty)
          OutlinedButton.icon(
            icon: const Icon(Icons.call_rounded),
            label: Text('${t(K.callDoctor)} ${p.doctorName}'),
            onPressed: () => ActionsService.call(p.doctorPhone),
          ),
        const SizedBox(height: 16),
        Text(t(K.disclaimer), textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
      ]),
    );
  }
}
