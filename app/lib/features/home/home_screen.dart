import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/tokens.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../feet/scan_result_screen.dart';
import '../meds/meds_screen.dart';

class HomeScreen extends StatelessWidget {
  final ValueChanged<int> onOpenTab;
  const HomeScreen({super.key, required this.onOpenTab});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final t = s.t;
    final plan = s.todayPlan();
    final last = s.lastScan;
    final needsAction = last != null && last.level == 'red' && last.acknowledgedAt == null;
    final hour = DateTime.now().hour;
    final name = s.profile?.name ?? '';
    final greet = hour < 12 ? t('home.morning') : (hour < 18 ? t('home.afternoon') : t('home.evening'));

    return ListView(
      padding: const EdgeInsets.fromLTRB(QSpace.s4, QSpace.s4, QSpace.s4, QSpace.s6),
      children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name.isEmpty ? greet : '$greet${s.lang == 'fr' ? ', ' : '، '}$name',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 2),
              Text(t('home.sub'), style: Theme.of(context).textTheme.bodyMedium),
            ]),
          ),
          const BrandLogo(width: 74),
        ]),
        const SizedBox(height: QSpace.s4),
        if (needsAction) ...[
          _RedBanner(onOpen: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ScanResultScreen(scan: last!)))),
          const SizedBox(height: QSpace.s3),
        ],
        _TodayCard(plan: plan, onOpenTab: onOpenTab),
        const SizedBox(height: QSpace.s3),
        SectionCard(
          title: t('home.feet'),
          trailing: last == null ? null : SourceBadge(last.source),
          onTap: () => onOpenTab(1),
          child: last == null
              ? Row(children: [
                  const Icon(Icons.directions_walk_rounded, color: QColors.navy700),
                  const SizedBox(width: 10),
                  Expanded(child: Text(t('home.noScan'), style: Theme.of(context).textTheme.bodyMedium)),
                ])
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: LevelBadge(last.level, large: true)),
                    Text(ago(s, last.time), style: Theme.of(context).textTheme.bodySmall),
                  ]),
                  const SizedBox(height: 6),
                  Text(t('home.feetDetail', {'dt': fmtNum(last.maxDt, s.lang), 'site': t('site.${last.site}')}),
                      style: Theme.of(context).textTheme.bodyMedium),
                  if (last.reviewStatus == 'confirmed' || last.reviewStatus == 'dismissed') ...[
                    const SizedBox(height: 10),
                    InfoBanner(
                      '${t('review.${last.reviewStatus}')}${last.reviewNote != null ? ' — ${last.reviewNote}' : ''}',
                      icon: Icons.medical_services_outlined,
                    ),
                  ],
                ]),
        ),
        const SizedBox(height: QSpace.s3),
        _GlucoseCard(onOpen: () => onOpenTab(2)),
        const SizedBox(height: QSpace.s3),
        Row(children: [
          Expanded(
            child: SectionCard(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MedsScreen())),
              child: Metric(label: t('home.adherence'), value: '${s.adherencePct()}', unit: '%'),
            ),
          ),
          const SizedBox(width: QSpace.s3),
          Expanded(
            child: SectionCard(
              onTap: () => onOpenTab(1),
              child: Metric(label: t('home.streak'), value: '${s.scanStreak()}', unit: t('home.days')),
            ),
          ),
        ]),
        const SizedBox(height: QSpace.s3),
        SectionCard(
          onTap: () => onOpenTab(3),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: QColors.sky100, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.forum_outlined, color: QColors.navy700),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t('home.ask'), style: Theme.of(context).textTheme.titleMedium),
                Text(t('home.askHint'), style: Theme.of(context).textTheme.bodySmall),
              ]),
            ),
            const Icon(Icons.chevron_right_rounded, color: QColors.ink3),
          ]),
        ),
        const SizedBox(height: QSpace.s4),
        _SyncLine(),
        const SizedBox(height: QSpace.s2),
        Text(t('common.notDiagnosis'), style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
      ],
    );
  }
}

class _RedBanner extends StatelessWidget {
  final VoidCallback onOpen;
  const _RedBanner({required this.onOpen});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Material(
      color: QColors.alert,
      borderRadius: BorderRadius.circular(QRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(QRadius.md),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(QSpace.s4),
          child: Row(children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.t('home.redTitle'), style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(s.t('home.redBody'), style: const TextStyle(color: Colors.white, fontSize: 14)),
              ]),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white),
          ]),
        ),
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  final ({int done, int total}) plan;
  final ValueChanged<int> onOpenTab;
  const _TodayCard({required this.plan, required this.onOpenTab});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final now = DateTime.now();
    bool today(DateTime d) => d.year == now.year && d.month == now.month && d.day == now.day;
    final scanDone = s.scans.any((x) => today(x.time));
    final glucoseDone = s.glucose.any((x) => today(x.time));
    final doses = s.meds.fold<int>(0, (a, m) => a + m.times.length);
    final dosesDone = s.meds.fold<int>(0, (a, m) => a + m.times.where((tm) => m.isTaken(now, tm)).length);

    Widget task(bool done, IconData icon, String label, VoidCallback onTap) => InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(QRadius.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(children: [
              Icon(done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: done ? QColors.ok : QColors.lineStrong, size: 26),
              const SizedBox(width: 12),
              Icon(icon, size: 20, color: QColors.ink2),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                      fontSize: 16,
                      color: done ? QColors.ink3 : QColors.ink,
                      decoration: done ? TextDecoration.lineThrough : null,
                    )),
              ),
              const Icon(Icons.chevron_right_rounded, color: QColors.ink3),
            ]),
          ),
        );

    return SectionCard(
      title: s.t('home.today'),
      trailing: Text('${plan.done}/${plan.total}', style: Theme.of(context).textTheme.titleMedium),
      child: Column(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: plan.total == 0 ? 0 : plan.done / plan.total,
            minHeight: 8,
            backgroundColor: QColors.sky100,
            color: plan.done == plan.total ? QColors.ok : QColors.navy700,
          ),
        ),
        const SizedBox(height: 6),
        task(scanDone, Icons.directions_walk_rounded, s.t('home.task.scan'), () => onOpenTab(1)),
        task(glucoseDone, Icons.water_drop_outlined, s.t('home.task.glucose'), () => onOpenTab(2)),
        task(
          doses > 0 && dosesDone == doses,
          Icons.medication_outlined,
          doses == 0 ? s.t('home.task.addMeds') : s.t('home.task.meds', {'done': '$dosesDone', 'total': '$doses'}),
          () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MedsScreen())),
        ),
      ]),
    );
  }
}

class _GlucoseCard extends StatelessWidget {
  final VoidCallback onOpen;
  const _GlucoseCard({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final g = s.glucose;
    final last = g.isEmpty ? null : g.last;
    final recent = g.length > 14 ? g.sublist(g.length - 14) : g;
    return SectionCard(
      title: s.t('home.glucose'),
      onTap: onOpen,
      child: last == null
          ? Text(s.t('home.noGlucose'), style: Theme.of(context).textTheme.bodyMedium)
          : Row(children: [
              Expanded(
                flex: 4,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Metric(
                    label: ago(s, last.time),
                    value: fmtNum(last.gL, s.lang, 2),
                    unit: 'g/L',
                    color: last.band == 'low' ? QColors.alert : (last.band == 'very_high' ? QColors.watch : QColors.ink),
                  ),
                  const SizedBox(height: 4),
                  Text(s.t('band.${last.band}'), style: Theme.of(context).textTheme.bodySmall),
                ]),
              ),
              if (recent.length >= 2)
                Expanded(
                  flex: 5,
                  child: SizedBox(
                    height: 64,
                    child: LineChart(LineChartData(
                      minY: 0.4,
                      maxY: 3.0,
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      lineTouchData: const LineTouchData(enabled: false),
                      rangeAnnotations: RangeAnnotations(horizontalRangeAnnotations: [
                        HorizontalRangeAnnotation(y1: 0.8, y2: 1.8, color: QColors.okBg),
                      ]),
                      lineBarsData: [
                        LineChartBarData(
                          spots: [for (var i = 0; i < recent.length; i++) FlSpot(i.toDouble(), recent[i].gL)],
                          isCurved: true,
                          preventCurveOverShooting: true,
                          color: QColors.navy700,
                          barWidth: 2.5,
                          dotData: const FlDotData(show: false),
                        ),
                      ],
                    )),
                  ),
                ),
            ]),
    );
  }
}

class _SyncLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final (icon, text) = switch (s.syncState) {
      'ok' => (Icons.cloud_done_outlined, s.t('sync.ok', {'when': ago(s, s.lastSyncAt)})),
      'syncing' => (Icons.cloud_sync_outlined, s.t('sync.syncing')),
      'offline' => (Icons.cloud_off_outlined, s.t('sync.offline', {'n': '${s.pendingSync}'})),
      'error' => (Icons.error_outline_rounded, s.t('sync.error')),
      _ => (Icons.phone_android_rounded, s.paired ? s.t('sync.idle') : s.t('sync.notPaired')),
    };
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 16, color: QColors.ink3),
      const SizedBox(width: 6),
      Flexible(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
    ]);
  }
}
