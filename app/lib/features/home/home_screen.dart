import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../state/app_state.dart';
import '../../widgets/foot_status.dart';
import '../meds/meds_screen.dart';

/// Diabetes dashboard: today's plan, glucose, medication, feet, learn.
class HomeScreen extends StatelessWidget {
  final void Function(int tab) onOpenTab;
  const HomeScreen({super.key, required this.onOpenTab});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final t = s.t;
    final (done, total) = s.todayPlan();
    final lastG = s.glucose.isEmpty ? null : s.glucose.last;
    final lastScan = s.scans.isEmpty ? null : s.scans.last;
    final nextMed = _nextDose(s);

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Text('${t(K.hello)} ${s.profile?.name ?? ''} 👋', style: Theme.of(context).textTheme.headlineSmall),
        ),
        Card(
          child: ListTile(
            title: Text(t(K.todayPlan)),
            subtitle: LinearProgressIndicator(value: total == 0 ? 0 : done / total, minHeight: 10,
                borderRadius: BorderRadius.circular(8)),
            trailing: Text('$done/$total\n🔥 ${s.scanStreak()} ${t(K.streak)}', textAlign: TextAlign.end),
          ),
        ),
        _Tile(
          icon: Icons.water_drop_rounded,
          title: t(K.glucose),
          value: lastG == null ? t(K.noData) : '${lastG.gL.toStringAsFixed(2)} g/L',
          color: lastG == null ? Colors.grey : _bandColor(lastG.band),
          action: t(K.addReading),
          onTap: () => onOpenTab(1),
        ),
        _Tile(
          icon: Icons.medication_rounded,
          title: t(K.meds),
          value: nextMed ?? t(K.noData),
          color: QadamColors.teal,
          action: t(K.meds),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MedsScreen())),
        ),
        Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => onOpenTab(2),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                FootStatusView(status: lastScan?.status ?? 'none', hotSite: lastScan?.status == 'green' ? null : lastScan?.site, size: 90),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(t(K.feet), style: Theme.of(context).textTheme.titleMedium),
                    Text(lastScan == null ? t(K.noData) : _statusText(t, lastScan.status)),
                    const SizedBox(height: 8),
                    FilledButton.icon(onPressed: () => onOpenTab(2), icon: const Icon(Icons.sensors), label: Text(t(K.scanNow))),
                  ]),
                ),
              ]),
            ),
          ),
        ),
        _Tile(
          icon: Icons.lightbulb_rounded,
          title: t(K.learn),
          value: t(K.myDiabetes),
          color: QadamColors.coral,
          action: t(K.askCoach),
          onTap: () => onOpenTab(3),
        ),
      ],
    );
  }

  static String? _nextDose(AppState s) {
    final now = DateTime.now();
    final hm = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    for (final m in s.meds) {
      for (final time in m.times) {
        if (!m.isTaken(now, time) && time.compareTo(hm) >= 0) return '${m.name} · $time';
      }
    }
    return null;
  }

  static Color _bandColor(String b) => switch (b) {
        'in_target' => QadamColors.ok,
        'out_of_target' => QadamColors.watch,
        _ => QadamColors.alert,
      };

  static String _statusText(String Function(String) t, String status) =>
      t(status == 'red' ? K.statusRed : status == 'amber' ? K.statusAmber : K.statusGreen);
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title, value, action;
  final Color color;
  final VoidCallback onTap;
  const _Tile({required this.icon, required this.title, required this.value, required this.color,
      required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.15), child: Icon(icon, color: color)),
          title: Text(title),
          subtitle: Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color)),
          trailing: TextButton(onPressed: onTap, child: Text(action)),
          onTap: onTap,
        ),
      );
}
