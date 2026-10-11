import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/tokens.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import 'scan_result_screen.dart';

class FootHistoryScreen extends StatelessWidget {
  const FootHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final t = s.t;
    final scans = s.scans.length > 30 ? s.scans.sublist(s.scans.length - 30) : s.scans;
    return Scaffold(
      appBar: AppBar(title: Text(t('history.title'))),
      body: scans.isEmpty
          ? EmptyState(icon: Icons.insights_rounded, title: t('history.empty.t'), body: t('history.empty.b'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(QSpace.s4, 0, QSpace.s4, QSpace.s6),
              children: [
                SectionCard(
                  title: t('history.chart'),
                  child: Column(children: [
                    SizedBox(
                      height: 210,
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: LineChart(LineChartData(
                          minY: 0,
                          maxY: 4,
                          gridData: FlGridData(
                            drawVerticalLine: false,
                            horizontalInterval: 1,
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
                                reservedSize: 30,
                                interval: 1,
                                getTitlesWidget: (v, meta) =>
                                    Text('${v.toInt()}°', style: const TextStyle(fontSize: 11, color: QColors.ink3)),
                              ),
                            ),
                          ),
                          extraLinesData: ExtraLinesData(horizontalLines: [
                            HorizontalLine(y: 2.2, color: QColors.alert, strokeWidth: 1.5, dashArray: [6, 4]),
                          ]),
                          lineBarsData: [
                            LineChartBarData(
                              spots: [for (var i = 0; i < scans.length; i++) FlSpot(i.toDouble(), scans[i].maxDt.clamp(0, 4).toDouble())],
                              isCurved: false,
                              color: QColors.navy700,
                              barWidth: 2,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                                  radius: 4.5,
                                  color: QColors.level(scans[index].level),
                                  strokeWidth: 1.5,
                                  strokeColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        )),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(t('history.legend'), style: Theme.of(context).textTheme.bodySmall),
                  ]),
                ),
                const SizedBox(height: QSpace.s3),
                Card(
                  child: Column(children: [
                    for (final sc in s.scans.reversed) ...[
                      ListTile(
                        title: LevelBadge(sc.level),
                        subtitle: Text('${fmtDay(sc.time)} · ${fmtNum(sc.maxDt, s.lang)} °C · ${t('site.${sc.site}')}'
                            '${sc.reviewStatus == 'confirmed' ? ' · ${t('review.short.confirmed')}' : ''}'),
                        trailing: SourceBadge(sc.source),
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ScanResultScreen(scan: sc))),
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
