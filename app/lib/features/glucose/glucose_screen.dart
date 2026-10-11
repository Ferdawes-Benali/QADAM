import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/tokens.dart';
import '../../models/models.dart';
import '../../services/actions_service.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';

class GlucoseScreen extends StatelessWidget {
  const GlucoseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final t = s.t;
    final all = s.glucose;
    final recent = all.length > 30 ? all.sublist(all.length - 30) : all;
    final week = all.where((g) => g.time.isAfter(DateTime.now().subtract(const Duration(days: 7)))).toList();
    final mean = week.isEmpty ? null : week.map((g) => g.gL).reduce((a, b) => a + b) / week.length;
    final inTarget = week.isEmpty ? null : (100 * week.where((g) => g.band == 'in_target').length / week.length).round();

    return Scaffold(
      appBar: AppBar(title: Text(t('glu.title'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => addGlucose(context),
        backgroundColor: QColors.navy700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(t('glu.add')),
      ),
      body: all.isEmpty
          ? EmptyState(
              icon: Icons.water_drop_outlined,
              title: t('glu.empty.t'),
              body: t('glu.empty.b'),
              action: FilledButton(onPressed: () => addGlucose(context), child: Text(t('glu.add'))),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(QSpace.s4, 0, QSpace.s4, 110),
              children: [
                SectionCard(
                  child: Row(children: [
                    Expanded(
                      child: Metric(
                        label: t('glu.last'),
                        value: fmtNum(all.last.gL, s.lang, 2),
                        unit: 'g/L',
                        color: all.last.band == 'low' ? QColors.alert : (all.last.band == 'very_high' ? QColors.watch : null),
                      ),
                    ),
                    Expanded(child: Metric(label: t('glu.mean7'), value: mean == null ? '—' : fmtNum(mean, s.lang, 2), unit: 'g/L')),
                    Expanded(child: Metric(label: t('glu.inTarget'), value: inTarget == null ? '—' : '$inTarget', unit: '%')),
                  ]),
                ),
                const SizedBox(height: QSpace.s3),
                if (recent.length >= 2)
                  SectionCard(
                    title: t('glu.chart'),
                    child: Column(children: [
                      SizedBox(
                        height: 200,
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: LineChart(LineChartData(
                            minY: 0.4,
                            maxY: 3.2,
                            gridData: FlGridData(
                              drawVerticalLine: false,
                              horizontalInterval: 0.5,
                              getDrawingHorizontalLine: (_) => FlLine(color: QColors.line, strokeWidth: 1),
                            ),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 34,
                                  interval: 0.5,
                                  getTitlesWidget: (v, meta) =>
                                      Text(v.toStringAsFixed(1), style: const TextStyle(fontSize: 11, color: QColors.ink3)),
                                ),
                              ),
                            ),
                            rangeAnnotations: RangeAnnotations(horizontalRangeAnnotations: [
                              HorizontalRangeAnnotation(y1: 0.8, y2: 1.8, color: QColors.okBg),
                            ]),
                            extraLinesData: ExtraLinesData(horizontalLines: [
                              HorizontalLine(y: 0.7, color: QColors.alert, strokeWidth: 1.5, dashArray: [6, 4]),
                            ]),
                            lineBarsData: [
                              LineChartBarData(
                                spots: [for (var i = 0; i < recent.length; i++) FlSpot(i.toDouble(), recent[i].gL.clamp(0.4, 3.2).toDouble())],
                                isCurved: true,
                                preventCurveOverShooting: true,
                                color: QColors.navy700,
                                barWidth: 2.5,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                                    radius: 3.5,
                                    color: recent[index].band == 'low'
                                        ? QColors.alert
                                        : (recent[index].band == 'very_high' ? QColors.watchFill : QColors.navy700),
                                    strokeWidth: 1.2,
                                    strokeColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          )),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(t('glu.legend'), style: Theme.of(context).textTheme.bodySmall),
                    ]),
                  ),
                const SizedBox(height: QSpace.s2),
                SectionTitle(t('glu.history')),
                Card(
                  child: Column(children: [
                    for (final g in all.reversed.take(40)) ...[
                      ListTile(
                        leading: _BandDot(g.band),
                        title: Text('${fmtNum(g.gL, s.lang, 2)} g/L · ${t('ctx.${g.context}')}'),
                        subtitle: Text('${fmtDay(g.time)} · ${t('band.${g.band}')}'),
                        trailing: IconButton(
                          tooltip: t('common.delete'),
                          icon: const Icon(Icons.delete_outline_rounded, color: QColors.ink3),
                          onPressed: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (c) => AlertDialog(
                                content: Text(t('glu.deleteQ')),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(c, false), child: Text(t('common.cancel'))),
                                  FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(t('common.delete'))),
                                ],
                              ),
                            );
                            if (ok == true) await s.deleteGlucose(g);
                          },
                        ),
                      ),
                      const Divider(indent: 16, endIndent: 16),
                    ],
                  ]),
                ),
              ],
            ),
    );
  }
}

class _BandDot extends StatelessWidget {
  final String band;
  const _BandDot(this.band);
  @override
  Widget build(BuildContext context) {
    final level = switch (band) { 'low' => 'red', 'very_high' => 'amber', 'in_target' => 'green', _ => 'none' };
    return LevelShape(level, size: 14);
  }
}

/// Add a reading (bottom sheet) then show fixed, rule-based guidance for low / very high values.
Future<void> addGlucose(BuildContext context) async {
  final s = context.read<AppState>();
  final res = await showModalBottomSheet<(double, String)>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _AddSheet(),
  );
  if (res == null || !context.mounted) return;
  final e = await s.addGlucose(res.$1, res.$2);
  if (!context.mounted) return;
  if (e.band == 'low') {
    ActionsService.playClip('sugar_low');
    await _lowDialog(context, s, e);
  } else if (e.band == 'very_high') {
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        icon: const Icon(Icons.trending_up_rounded, color: QColors.watch, size: 40),
        title: Text(s.t('glu.high.title')),
        content: Text(s.t('glu.high.body')),
        actions: [FilledButton(onPressed: () => Navigator.pop(c), child: Text(s.t('common.ok')))],
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.t('glu.saved.${e.band}'))));
  }
}

Future<void> _lowDialog(BuildContext context, AppState s, GlucoseEntry e) => showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: QColors.alert, size: 44),
        title: Text(s.t('glu.low.title', {'v': fmtNum(e.gL, s.lang, 2)})),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final k in const [1, 2, 3])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('$k. ${s.t('glu.low.$k')}', style: const TextStyle(fontSize: 16, height: 1.4)),
            ),
          const SizedBox(height: 6),
          InfoBanner(s.t('glu.low.emergency'), tone: BannerTone.alert, icon: Icons.emergency_outlined),
        ]),
        actions: [
          if ((s.profile?.familyPhone ?? '').isNotEmpty)
            TextButton(
              onPressed: () => ActionsService.whatsapp(
                  s.profile!.familyPhone, s.t('glu.low.familyMsg', {'name': s.profile!.name, 'v': fmtNum(e.gL, s.lang, 2)})),
              child: Text(s.t('action.tellFamily')),
            ),
          FilledButton(onPressed: () => Navigator.pop(c), child: Text(s.t('common.understood'))),
        ],
      ),
    );

class _AddSheet extends StatefulWidget {
  const _AddSheet();
  @override
  State<_AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends State<_AddSheet> {
  final ctrl = TextEditingController();
  String ctx = 'fasting';
  String? error;

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  void _save(AppState s) {
    final raw = ctrl.text.trim().replaceAll(',', '.');
    var v = double.tryParse(raw);
    // Accept mg/dL out of habit (e.g. 120) and convert: 1 g/L = 100 mg/dL.
    if (v != null && v >= 20 && v <= 600) v = v / 100;
    if (v == null || v < 0.2 || v > 6.0) {
      setState(() => error = s.t('glu.err.range'));
      return;
    }
    Navigator.pop(context, (double.parse(v.toStringAsFixed(2)), ctx));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final t = s.t;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(t('glu.add'), style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')), LengthLimitingTextInputFormatter(5)],
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
          decoration: InputDecoration(labelText: t('glu.value'), suffixText: 'g/L', hintText: '1,20', errorText: error),
          onSubmitted: (_) => _save(s),
        ),
        const SizedBox(height: 16),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'fasting', label: Text(t('ctx.fasting'))),
            ButtonSegment(value: 'after_meal', label: Text(t('ctx.after_meal'))),
            ButtonSegment(value: 'other', label: Text(t('ctx.other'))),
          ],
          selected: {ctx},
          showSelectedIcon: false,
          onSelectionChanged: (v) => setState(() => ctx = v.first),
        ),
        const SizedBox(height: 20),
        FilledButton(onPressed: () => _save(s), child: Text(t('common.save'))),
      ]),
    );
  }
}
