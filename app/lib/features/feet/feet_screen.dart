import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/tokens.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../../widgets/feet_diagram.dart';
import '../settings/connection_screen.dart';
import 'foot_history_screen.dart';
import 'scan_result_screen.dart';

class FeetScreen extends StatelessWidget {
  const FeetScreen({super.key});

  Future<void> _scan(BuildContext context, AppState s) async {
    final scan = await s.startScan();
    if (scan != null && context.mounted) {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ScanResultScreen(scan: scan, fresh: true)));
      s.resetScan();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final t = s.t;
    final st = s.deviceState;
    final measuring = s.scanPhase == ScanPhase.measuring;
    final canScan = st == DeviceState.online && !measuring;
    final l = s.liveTemp('left'), r = s.liveTemp('right');

    return Scaffold(
      appBar: AppBar(
        title: Text(t('feet.title')),
        actions: [
          IconButton(
            tooltip: t('feet.history'),
            icon: const Icon(Icons.insights_rounded),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FootHistoryScreen())),
          ),
          IconButton(
            tooltip: t('conn.title'),
            icon: const Icon(Icons.settings_input_antenna_rounded),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ConnectionScreen())),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(QSpace.s4, 0, QSpace.s4, QSpace.s6),
        children: [
          _DeviceCard(state: st),
          const SizedBox(height: QSpace.s3),
          SectionCard(
            child: Column(children: [
              if (s.liveSimulated) ...[
                InfoBanner(t('feet.simBanner'), icon: Icons.science_outlined, tone: BannerTone.sim),
                const SizedBox(height: QSpace.s3),
              ],
              FeetDiagram(height: 170, semanticLabel: t('feet.diagramLabel')),
              const SizedBox(height: QSpace.s3),
              Row(children: [
                Expanded(child: _Temp(label: t('side.left'), value: l, lang: s.lang)),
                Expanded(child: _Temp(label: t('side.right'), value: r, lang: s.lang)),
                Expanded(
                  child: _Temp(
                    label: t('feet.difference'),
                    value: (l != null && r != null) ? (l - r).abs() : null,
                    lang: s.lang,
                    highlight: l != null && r != null && (l - r).abs() >= 2.2,
                  ),
                ),
              ]),
              const SizedBox(height: QSpace.s2),
              Text(t('feet.liveNote'), style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
            ]),
          ),
          const SizedBox(height: QSpace.s3),
          if (measuring)
            SectionCard(
              child: Column(children: [
                Text(t('feet.measuring'), style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
                const SizedBox(height: 6),
                Text(t('feet.stand'), style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                const SizedBox(height: QSpace.s4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: s.scanProgress,
                    minHeight: 10,
                    backgroundColor: QColors.sky100,
                    color: QColors.navy700,
                  ),
                ),
                const SizedBox(height: 8),
                Text('${(10 - s.scanProgress * 10).ceil()} s', style: Theme.of(context).textTheme.titleMedium),
              ]),
            )
          else ...[
            SizedBox(
              height: 60,
              child: FilledButton.icon(
                onPressed: canScan ? () => _scan(context, s) : null,
                icon: const Icon(Icons.play_arrow_rounded, size: 28),
                label: Text(t('feet.start')),
              ),
            ),
            const SizedBox(height: 8),
            Text(canScan ? t('feet.startHint') : t('feet.cannotScan'),
                style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
          ],
          if (s.scanPhase == ScanPhase.error && s.scanError != null) ...[
            const SizedBox(height: QSpace.s3),
            InfoBanner(t(s.scanError!), tone: BannerTone.warn, icon: Icons.report_gmailerrorred_rounded),
          ],
          const SizedBox(height: QSpace.s4),
          if (s.scans.isNotEmpty) ...[
            Row(children: [
              Expanded(child: SectionTitle(t('feet.recent'))),
              TextButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FootHistoryScreen())),
                child: Text(t('common.seeAll')),
              ),
            ]),
            Card(
              child: Column(children: [
                for (final sc in s.scans.reversed.take(4)) ...[
                  ListTile(
                    title: LevelBadge(sc.level),
                    subtitle: Text('${fmtDay(sc.time)} · ${fmtNum(sc.maxDt, s.lang)} °C · ${t('site.${sc.site}')}'),
                    trailing: sc.isSimulated ? const SourceBadge('simulated') : const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ScanResultScreen(scan: sc))),
                  ),
                  if (sc != s.scans.reversed.take(4).last) const Divider(indent: 16, endIndent: 16),
                ],
              ]),
            ),
          ],
          const SizedBox(height: QSpace.s4),
          InfoBanner(t('feet.selfCheck'), icon: Icons.visibility_outlined),
        ],
      ),
    );
  }
}

class _Temp extends StatelessWidget {
  final String label;
  final double? value;
  final String lang;
  final bool highlight;
  const _Temp({required this.label, required this.value, required this.lang, this.highlight = false});
  @override
  Widget build(BuildContext context) => Column(children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 2),
        Text(value == null ? '—' : '${fmtNum(value!, lang)}°',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: highlight ? QColors.watch : QColors.ink,
            )),
      ]);
}

class _DeviceCard extends StatelessWidget {
  final DeviceState state;
  const _DeviceCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final t = s.t;
    final (color, label) = switch (state) {
      DeviceState.online => (const Color(0xFF18A058), t('dev.online')),
      DeviceState.fault => (QColors.watchFill, t('dev.fault')),
      DeviceState.stale => (QColors.watchFill, t('dev.stale')),
      DeviceState.waiting => (QColors.watchFill, t('dev.waiting')),
      DeviceState.connecting => (QColors.sky400, t('dev.connecting')),
      DeviceState.brokerDown => (QColors.ink3, t('dev.brokerDown')),
      DeviceState.bridgeError => (QColors.alert, t('dev.bridgeError')),
      DeviceState.notConfigured => (QColors.ink3, t('dev.notConfigured')),
    };
    final help = switch (state) {
      DeviceState.notConfigured => t('dev.help.notConfigured'),
      DeviceState.brokerDown => t('dev.help.brokerDown', {'host': s.mqttHost}),
      DeviceState.waiting => t('dev.help.waiting'),
      DeviceState.stale => t('dev.help.stale', {'when': ago(s, s.lastFrameAt)}),
      DeviceState.fault => t('dev.help.fault'),
      DeviceState.bridgeError => '${t('dev.help.bridgeError')} ${(s.bridgeStatus?['detail'] ?? '').toString()}',
      _ => null,
    };
    return SectionCard(
      onTap: state == DeviceState.online
          ? null
          : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ConnectionScreen())),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: Theme.of(context).textTheme.titleMedium)),
          if (s.liveSource != null && (state == DeviceState.online || state == DeviceState.fault)) SourceBadge(s.liveSource!),
        ]),
        if (help != null) ...[
          const SizedBox(height: 6),
          Text(help, style: Theme.of(context).textTheme.bodyMedium),
        ],
        if (state == DeviceState.online) ...[
          const SizedBox(height: 4),
          Text(t('dev.detail', {'device': s.deviceId, 'when': ago(s, s.lastFrameAt)}), style: Theme.of(context).textTheme.bodySmall),
        ],
      ]),
    );
  }
}
