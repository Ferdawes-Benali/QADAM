import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../services/actions_service.dart';
import '../../services/gemini_service.dart';
import '../../state/app_state.dart';

class GlucoseScreen extends StatelessWidget {
  const GlucoseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final t = s.t;
    final recent = s.glucose.length > 30 ? s.glucose.sublist(s.glucose.length - 30) : s.glucose;
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context, s),
        icon: const Icon(Icons.add),
        label: Text(t(K.addReading)),
      ),
      body: ListView(padding: const EdgeInsets.only(bottom: 96), children: [
        Padding(padding: const EdgeInsets.all(20), child: Text(t(K.glucose), style: Theme.of(context).textTheme.headlineSmall)),
        if (recent.length >= 2)
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 24, 24, 8),
              child: SizedBox(
                height: 200,
                child: LineChart(LineChartData(
                  minY: 0.4,
                  maxY: 3.0,
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  titlesData: const FlTitlesData(
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  extraLinesData: ExtraLinesData(horizontalLines: [
                    HorizontalLine(y: 0.70, color: QadamColors.alert, dashArray: [6, 4]),
                    HorizontalLine(y: 1.80, color: QadamColors.watch, dashArray: [6, 4]),
                  ]),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [for (var i = 0; i < recent.length; i++) FlSpot(i.toDouble(), recent[i].gL)],
                      isCurved: true,
                      color: QadamColors.coral,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                )),
              ),
            ),
          ),
        for (final g in s.glucose.reversed.take(20))
          Card(
            child: ListTile(
              title: Text('${g.gL.toStringAsFixed(2)} g/L · ${g.context == 'fasting' ? t(K.fasting) : t(K.afterMeal)}'),
              subtitle: Text(g.time.toString().substring(0, 16)),
              trailing: IconButton(
                icon: const Icon(Icons.auto_awesome),
                tooltip: t(K.explain),
                onPressed: () => _explain(context, s, g),
              ),
            ),
          ),
      ]),
    );
  }

  Future<void> _add(BuildContext context, AppState s) async {
    final ctrl = TextEditingController();
    var ctx = 'fasting';
    final value = await showDialog<double>(
      context: context,
      builder: (dctx) => StatefulBuilder(
        builder: (dctx, setD) => AlertDialog(
          title: Text(s.t(K.addReading)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'g/L (ex: 1.20)'),
            ),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'fasting', label: Text(s.t(K.fasting))),
                ButtonSegment(value: 'after_meal', label: Text(s.t(K.afterMeal))),
              ],
              selected: {ctx},
              onSelectionChanged: (v) => setD(() => ctx = v.first),
            ),
          ]),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dctx, double.tryParse(ctrl.text.replaceAll(',', '.'))),
              child: Text(s.t(K.save)),
            ),
          ],
        ),
      ),
    );
    if (value == null || value <= 0 || value > 6) return;
    final e = GlucoseEntry(DateTime.now(), value, ctx);
    await s.addGlucose(e);
    if (!context.mounted) return;
    if (e.band == 'low' || e.band == 'very_high') {
      if (e.band == 'low') ActionsService.playClip('sugar_low');
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          icon: const Icon(Icons.warning_rounded, color: QadamColors.alert, size: 48),
          content: Text(s.t(e.band == 'low' ? K.lowSugar : K.highSugar), style: const TextStyle(fontSize: 18)),
          actions: [
            if ((s.profile?.familyPhone ?? '').isNotEmpty)
              TextButton(
                onPressed: () => ActionsService.whatsapp(s.profile!.familyPhone,
                    'Qadam: ${s.profile!.name} - glycémie ${e.gL.toStringAsFixed(2)} g/L. Merci de l\'appeler.'),
                child: Text(s.t(K.tellFamily)),
              ),
            FilledButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          ],
        ),
      );
    }
  }

  Future<void> _explain(BuildContext context, AppState s, GlucoseEntry g) async {
    showModalBottomSheet(
      context: context,
      builder: (_) => FutureBuilder<String>(
        future: GeminiService().explainGlucose(g, s.profile!, s.lang),
        builder: (_, snap) => Padding(
          padding: const EdgeInsets.all(24),
          child: snap.hasData ? Text(snap.data!, style: const TextStyle(fontSize: 18)) : const LinearProgressIndicator(),
        ),
      ),
    );
  }
}
