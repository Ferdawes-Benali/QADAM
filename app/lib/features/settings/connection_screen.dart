import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/tokens.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';

/// Mat (MQTT broker on the laptop) + care team hub (pairing code) + demo mode.
class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});
  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  late final AppState s = context.read<AppState>();
  late final host = TextEditingController(text: s.mqttHost);
  late final port = TextEditingController(text: '${s.mqttPort}');
  late final device = TextEditingController(text: s.deviceId);
  late final hub = TextEditingController(text: s.hubUrl.isEmpty ? 'http://' : s.hubUrl);
  final code = TextEditingController();
  bool connecting = false, pairing = false;
  String? pairError;

  @override
  void dispose() {
    for (final c in [host, port, device, hub, code]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _connect() async {
    setState(() => connecting = true);
    final ok = await s.connectMat(host: host.text, port: int.tryParse(port.text) ?? 1883, device: device.text);
    if (!mounted) return;
    setState(() => connecting = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? s.t('conn.ok') : s.t('conn.fail'))));
  }

  Future<void> _pair() async {
    setState(() {
      pairing = true;
      pairError = null;
    });
    final err = await s.pair(hub.text, code.text);
    if (!mounted) return;
    setState(() {
      pairing = false;
      pairError = err == null ? null : s.t(err);
    });
    if (err == null) {
      code.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.t('pair.ok', {'ref': s.patientRef ?? ''}))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final t = st.t;
    return Scaffold(
      appBar: AppBar(title: Text(t('conn.title'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(QSpace.s4, 0, QSpace.s4, QSpace.s6),
        children: [
          SectionCard(
            title: t('conn.mat'),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(t('conn.matHelp'), style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 12),
              TextField(
                controller: host,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(labelText: t('conn.host'), hintText: '192.168.43.10'),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: port,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(labelText: t('conn.port')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: TextField(controller: device, decoration: InputDecoration(labelText: t('conn.device'))),
                ),
              ]),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: connecting ? null : _connect,
                child: connecting
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : Text(t('conn.connect')),
              ),
              const SizedBox(height: 10),
              Text(t('conn.state.${st.deviceState.name}'), style: Theme.of(context).textTheme.bodySmall),
              if (st.advanced && st.bridgeStatus != null) ...[
                const SizedBox(height: 8),
                Text('bridge: ${st.bridgeStatus}', style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
                Text('rejected frames: ${st.mqtt.rejected}', style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
              ],
            ]),
          ),
          const SizedBox(height: QSpace.s3),
          SectionCard(
            title: t('conn.hub'),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (st.paired) ...[
                InfoBanner(t('conn.paired', {'ref': st.patientRef ?? '', 'url': st.hubUrl}), icon: Icons.verified_user_outlined),
                const SizedBox(height: 10),
                Text(
                    '${t('sync.label')}: ${t('sync.state.${st.syncState}')} · ${t('sync.pending', {'n': '${st.pendingSync}'})}'
                    '${st.lastSyncAt != null ? ' · ${ago(st, st.lastSyncAt)}' : ''}',
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: OutlinedButton(onPressed: () => st.syncNow(), child: Text(t('sync.now')))),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => st.unpair(),
                      style: OutlinedButton.styleFrom(foregroundColor: QColors.alert),
                      child: Text(t('conn.unpair')),
                    ),
                  ),
                ]),
              ] else ...[
                Text(t('conn.hubHelp'), style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 12),
                TextField(
                  controller: hub,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(labelText: t('conn.hubUrl'), hintText: 'http://192.168.43.10:8000'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: code,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
                  decoration: InputDecoration(labelText: t('conn.code')),
                ),
                if (!st.consentShare) ...[
                  const SizedBox(height: 10),
                  InfoBanner(t('conn.noConsent'), tone: BannerTone.warn),
                ],
                if (pairError != null) ...[
                  const SizedBox(height: 10),
                  InfoBanner(pairError!, tone: BannerTone.alert, icon: Icons.error_outline_rounded),
                ],
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: pairing || !st.consentShare ? null : _pair,
                  child: pairing
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : Text(t('conn.pair')),
                ),
              ],
            ]),
          ),
          const SizedBox(height: QSpace.s3),
          SectionCard(
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: st.demoMode,
              onChanged: st.setDemoMode,
              title: Text(t('conn.demo'), style: Theme.of(context).textTheme.titleMedium),
              subtitle: Text(t('conn.demoHelp')),
            ),
          ),
        ],
      ),
    );
  }
}
