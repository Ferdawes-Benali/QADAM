import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../services/actions_service.dart';
import '../../state/app_state.dart';
import '../../widgets/foot_status.dart';
import '../alert/alert_screen.dart';

class FeetScreen extends StatefulWidget {
  const FeetScreen({super.key});
  @override
  State<FeetScreen> createState() => _FeetScreenState();
}

class _FeetScreenState extends State<FeetScreen> {
  StreamSubscription<FootScan>? _sub;
  final _host = TextEditingController();
  final _checks = <String, bool>{
    'Rougeur / حمورية': false,
    'Plaie ou fissure / جرح ولا تشقيق': false,
    'Gonflement / نفخة': false,
    'Ongle incarné / ظفر داخل في اللحم': false,
    'Peau très sèche / جلد يابس برشا': false,
  };

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    _host.text = s.mqttHost;
    _sub = s.newScans.listen((scan) {
      ActionsService.playClip('foot_${scan.status}');
      if (scan.status != 'green' && mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => AlertScreen(scan: scan)));
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final t = s.t;
    final scan = s.lastLiveScan ?? (s.scans.isEmpty ? null : s.scans.last);
    return ListView(padding: const EdgeInsets.only(bottom: 24), children: [
      Padding(padding: const EdgeInsets.all(20), child: Text(t(K.feet), style: Theme.of(context).textTheme.headlineSmall)),
      // ---- connection to the mat (MQTT) ----
      Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Icon(Icons.circle, size: 14, color: s.mqttConnected ? QadamColors.ok : Colors.grey),
            const SizedBox(width: 8),
            Text('${t(K.liveMat)} : ${s.mqttConnected ? t(K.connected) : t(K.disconnected)}'),
            const Spacer(),
            SizedBox(width: 130, child: TextField(controller: _host, decoration: const InputDecoration(isDense: true, labelText: 'IP PC'))),
            IconButton(
              icon: const Icon(Icons.link),
              onPressed: () async {
                final ok = await s.connectMat(host: _host.text.trim());
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'MQTT OK' : 'MQTT: connexion impossible')));
              },
            ),
          ]),
        ),
      ),
      // ---- live status ----
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            FootStatusView(status: scan?.status ?? 'none', hotSite: scan?.status == 'green' ? null : scan?.site, size: 150),
            const SizedBox(height: 12),
            Text(scan == null ? t(K.scanNow) : t(scan.status == 'red' ? K.statusRed : scan.status == 'amber' ? K.statusAmber : K.statusGreen),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: QadamColors.forStatus(scan?.status ?? 'none'))),
            if (scan != null) ...[
              const SizedBox(height: 8),
              Table(
                border: TableBorder.all(color: Colors.black12),
                children: [
                  TableRow(children: [for (final h in ['', t(K.left), t(K.right), t(K.difference)]) _cell(h, bold: true)]),
                  for (final site in scan.dt.keys)
                    TableRow(children: [
                      _cell(site),
                      _cell(scan.left[site]?.toStringAsFixed(1) ?? '-'),
                      _cell(scan.right[site]?.toStringAsFixed(1) ?? '-'),
                      _cell('${scan.dt[site]!.toStringAsFixed(1)} °C', color: scan.dt[site]! >= 2.2 ? QadamColors.alert : null),
                    ]),
                ],
              ),
              if (scan.status != 'green')
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AlertScreen(scan: scan))),
                  child: Text(t(K.explain)),
                ),
            ],
            Text(s.demoMode ? t(K.demoMode) : '', style: Theme.of(context).textTheme.bodySmall),
          ]),
        ),
      ),
      // ---- daily self-check ----
      Card(
        child: ExpansionTile(
          leading: const Icon(Icons.checklist_rounded),
          title: Text(t(K.selfCheck)),
          children: [
            for (final k in _checks.keys)
              CheckboxListTile(value: _checks[k], title: Text(k), onChanged: (v) => setState(() => _checks[k] = v ?? false)),
            if (_checks.values.any((v) => v))
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(t(K.statusRed), style: const TextStyle(color: QadamColors.alert)),
              ),
          ],
        ),
      ),
      // ---- history ----
      Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 4), child: Text(t(K.history), style: Theme.of(context).textTheme.titleMedium)),
      for (final h in s.scans.reversed.take(10))
        ListTile(
          leading: Icon(Icons.circle, color: QadamColors.forStatus(h.status)),
          title: Text('${h.maxDt.toStringAsFixed(1)} °C · ${h.site}'),
          subtitle: Text(h.time.toString().substring(0, 16)),
        ),
    ]);
  }

  Widget _cell(String text, {bool bold = false, Color? color}) => Padding(
        padding: const EdgeInsets.all(6),
        child: Text(text, textAlign: TextAlign.center,
            style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.normal, color: color)),
      );
}
