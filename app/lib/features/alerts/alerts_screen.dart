import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/tokens.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../feet/scan_result_screen.dart';

/// Every warning the patient received, with what happened next:
/// sent to the care team? reviewed by a clinician? acknowledged by the patient?
class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final t = s.t;
    final items = <({DateTime time, Widget tile})>[];
    for (final sc in s.scans.where((x) => x.level != 'green')) {
      items.add((
        time: sc.time,
        tile: ListTile(
          leading: Padding(padding: const EdgeInsets.only(top: 4), child: LevelShape(sc.level, size: 16)),
          title: Text(t('alerts.foot', {'dt': fmtNum(sc.maxDt, s.lang), 'site': t('site.${sc.site}')})),
          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(fmtDay(sc.time)),
            const SizedBox(height: 4),
            Wrap(spacing: 6, runSpacing: 6, children: [
              if (sc.isSimulated) const SourceBadge('simulated'),
              _Chip(
                sc.reviewStatus == 'confirmed'
                    ? t('review.short.confirmed')
                    : sc.reviewStatus == 'dismissed'
                        ? t('review.short.dismissed')
                        : (sc.hubLevel != null ? t('alerts.sent') : (s.paired ? t('alerts.pending') : t('alerts.local'))),
                sc.reviewStatus == 'confirmed' ? QColors.alertBg : QColors.sky50,
              ),
              if (sc.acknowledgedAt != null) _Chip(t('alerts.acked'), QColors.okBg),
            ]),
            if (sc.reviewNote != null) ...[
              const SizedBox(height: 6),
              Text('“${sc.reviewNote}”', style: const TextStyle(fontStyle: FontStyle.italic, color: QColors.ink)),
            ],
          ]),
          isThreeLine: true,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ScanResultScreen(scan: sc))),
        ),
      ));
    }
    for (final g in s.glucose.where((x) => x.band == 'low' || x.band == 'very_high')) {
      items.add((
        time: g.time,
        tile: ListTile(
          leading: Padding(
              padding: const EdgeInsets.only(top: 4), child: LevelShape(g.band == 'low' ? 'red' : 'amber', size: 16)),
          title: Text(t('alerts.glucose.${g.band}', {'v': fmtNum(g.gL, s.lang, 2)})),
          subtitle: Text(fmtDay(g.time)),
        ),
      ));
    }
    items.sort((a, b) => b.time.compareTo(a.time));
    return Scaffold(
      appBar: AppBar(
        title: Text(t('alerts.title')),
        actions: [
          if (s.paired)
            IconButton(tooltip: t('sync.now'), icon: const Icon(Icons.sync_rounded), onPressed: () => s.syncNow()),
        ],
      ),
      body: items.isEmpty
          ? EmptyState(icon: Icons.notifications_none_rounded, title: t('alerts.empty.t'), body: t('alerts.empty.b'))
          : ListView(padding: const EdgeInsets.fromLTRB(QSpace.s4, 0, QSpace.s4, QSpace.s6), children: [
              InfoBanner(t('alerts.explain'), icon: Icons.info_outline_rounded),
              const SizedBox(height: QSpace.s3),
              Card(
                child: Column(children: [
                  for (final it in items) ...[it.tile, const Divider(indent: 16, endIndent: 16)],
                ]),
              ),
            ]),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final Color bg;
  const _Chip(this.text, this.bg);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99), border: Border.all(color: QColors.line)),
        child: Text(text, style: const TextStyle(fontSize: 12.5, color: QColors.ink2, fontWeight: FontWeight.w500)),
      );
}
