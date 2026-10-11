import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/tokens.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../alerts/alerts_screen.dart';
import '../care/care_screen.dart';
import '../meds/meds_screen.dart';
import '../settings/about_screen.dart';
import '../settings/connection_screen.dart';
import '../settings/settings_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final t = s.t;
    final p = s.profile;
    final reviewed = s.scans.where((x) => x.reviewStatus == 'confirmed' && x.acknowledgedAt == null).length;
    void open(Widget w) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));
    Widget item(IconData icon, String title, String sub, Widget page, {Widget? badge, VoidCallback? before}) => ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: QColors.sky100, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: QColors.navy700),
          ),
          title: Text(title, style: Theme.of(context).textTheme.titleMedium),
          subtitle: Text(sub),
          trailing: badge ?? const Icon(Icons.chevron_right_rounded, color: QColors.ink3),
          onTap: () {
            before?.call();
            open(page);
          },
        );
    return ListView(
      padding: const EdgeInsets.fromLTRB(QSpace.s4, QSpace.s4, QSpace.s4, QSpace.s6),
      children: [
        SectionCard(
          child: Row(children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: QColors.navy900,
              child: Text((p?.name.isNotEmpty ?? false) ? p!.name.substring(0, 1).toUpperCase() : '·',
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p?.name ?? '', style: Theme.of(context).textTheme.titleLarge),
                Text('${t('type.${p?.diabetesType ?? 't2'}')} · ${t('riskLabel.${p?.footRisk ?? 'low'}')}',
                    style: Theme.of(context).textTheme.bodyMedium),
                if (s.patientRef != null) Text(t('more.ref', {'ref': s.patientRef!}), style: Theme.of(context).textTheme.bodySmall),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: QSpace.s3),
        Card(
          child: Column(children: [
            item(Icons.notifications_none_rounded, t('more.alerts'), t('more.alertsSub'), const AlertsScreen(),
                badge: reviewed > 0 ? Badge(label: Text('$reviewed')) : null, before: s.syncNow),
            const Divider(indent: 72),
            item(Icons.medication_outlined, t('more.meds'), t('more.medsSub'), const MedsScreen()),
            const Divider(indent: 72),
            item(Icons.people_alt_outlined, t('more.care'), t('more.careSub'), const CareScreen()),
            const Divider(indent: 72),
            item(Icons.settings_input_antenna_rounded, t('more.conn'), t('more.connSub'), const ConnectionScreen()),
          ]),
        ),
        const SizedBox(height: QSpace.s3),
        Card(
          child: Column(children: [
            item(Icons.tune_rounded, t('more.settings'), t('more.settingsSub'), const SettingsScreen()),
            const Divider(indent: 72),
            item(Icons.info_outline_rounded, t('about.title'), t('more.aboutSub'), const AboutScreen()),
          ]),
        ),
        const SizedBox(height: QSpace.s4),
        Text(t('common.notDiagnosis'), textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
