import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/tokens.dart';
import '../../models/models.dart';
import '../../services/actions_service.dart';
import '../../services/foot_rule.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../../widgets/feet_diagram.dart';

/// Result of one scan: status, WHY (triggering parameters + confidence), WHAT TO DO (fixed, not AI),
/// and the care team's decision once a clinician has reviewed it (human in the loop).
class ScanResultScreen extends StatefulWidget {
  final FootScan scan;
  final bool fresh;
  const ScanResultScreen({super.key, required this.scan, this.fresh = false});
  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.fresh) ActionsService.playClip('foot_${widget.scan.level}');
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final t = s.t;
    final sc = widget.scan;
    final p = s.profile;
    final l = sc.left[sc.site] ?? 0, r = sc.right[sc.site] ?? 0;
    final warm = sc.level != 'green';
    final lvlColor = QColors.levelText(sc.level);

    return Scaffold(
      appBar: AppBar(title: Text(t('result.title')), backgroundColor: QColors.levelBg(sc.level)),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            color: QColors.levelBg(sc.level),
            padding: const EdgeInsets.fromLTRB(QSpace.s4, 0, QSpace.s4, QSpace.s5),
            child: Column(children: [
              if (sc.isSimulated) ...[
                InfoBanner(t('result.simulated'), icon: Icons.science_outlined, tone: BannerTone.sim),
                const SizedBox(height: QSpace.s3),
              ],
              LevelBadge(sc.level, large: true),
              const SizedBox(height: 8),
              Text(t('result.head.${sc.level}'),
                  textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: QColors.ink)),
              const SizedBox(height: QSpace.s4),
              FeetDiagram(
                height: 190,
                sites: sc.left.keys.toSet(),
                hotSite: sc.site,
                warmerSide: sc.warmerSide,
                level: sc.level,
                semanticLabel: t('result.diagram', {'side': t('side.${sc.warmerSide}'), 'site': t('site.${sc.site}')}),
              ),
              const SizedBox(height: 6),
              Text(fmtDay(sc.time), style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              SourceBadge(sc.source),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(QSpace.s4),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              SectionCard(
                title: t('result.why'),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Metric(label: t('side.left'), value: fmtNum(l, s.lang, 1), unit: '°C')),
                    Expanded(child: Metric(label: t('side.right'), value: fmtNum(r, s.lang, 1), unit: '°C')),
                    Expanded(
                      child: Metric(
                          label: t('feet.difference'), value: fmtNum(sc.maxDt, s.lang, 1), unit: '°C', color: warm ? lvlColor : null),
                    ),
                  ]),
                  const SizedBox(height: QSpace.s3),
                  _ThresholdBar(value: sc.maxDt, level: sc.level),
                  const SizedBox(height: QSpace.s3),
                  Text(
                    t('result.why.${sc.level}', {
                      'dt': fmtNum(sc.maxDt, s.lang),
                      'site': t('site.${sc.site}'),
                      'side': t('side.${sc.warmerSide}'),
                      'th': fmtNum(FootRule.threshold, s.lang),
                    }),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (sc.demo && sc.level == 'red') ...[
                    const SizedBox(height: 8),
                    Text(t('result.demoNote'), style: Theme.of(context).textTheme.bodySmall),
                  ],
                  const Divider(height: 28),
                  Row(children: [
                    Expanded(
                        child: Text(t('result.confidence', {'n': '${sc.confidence}'}),
                            style: Theme.of(context).textTheme.titleMedium)),
                    Text(t('conf.${sc.confidenceLabel}'),
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: sc.confidenceLabel == 'high'
                                ? QColors.ok
                                : (sc.confidenceLabel == 'medium' ? QColors.watch : QColors.alert))),
                  ]),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                        value: sc.confidence / 100, minHeight: 8, backgroundColor: QColors.sky100, color: QColors.navy700),
                  ),
                  const SizedBox(height: 8),
                  Text(t('result.confidenceHelp'), style: Theme.of(context).textTheme.bodySmall),
                  if (sc.confidenceLabel == 'low') ...[
                    const SizedBox(height: 8),
                    InfoBanner(t('result.lowConfidence'), tone: BannerTone.warn, icon: Icons.replay_rounded),
                  ],
                ]),
              ),
              const SizedBox(height: QSpace.s3),
              SectionCard(
                title: t('result.todo'),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  for (final k in const [1, 2, 3])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(color: QColors.sky100, shape: BoxShape.circle),
                          child: Text('$k', style: const TextStyle(fontWeight: FontWeight.w600, color: QColors.navy800)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(t('todo.${sc.level}.$k'), style: Theme.of(context).textTheme.bodyLarge)),
                      ]),
                    ),
                  InfoBanner(t('todo.emergency'), icon: Icons.emergency_outlined, tone: BannerTone.alert),
                ]),
              ),
              const SizedBox(height: QSpace.s3),
              if (sc.level == 'red') ...[
                if ((p?.doctorPhone ?? '').isNotEmpty)
                  FilledButton.icon(
                    onPressed: () => ActionsService.call(p!.doctorPhone),
                    icon: const Icon(Icons.call_rounded),
                    label: Text(t('action.callDoctor', {'name': p!.doctorName.isEmpty ? '' : p.doctorName})),
                  ),
                if ((p?.familyPhone ?? '').isNotEmpty) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => ActionsService.whatsapp(
                        p!.familyPhone,
                        t('action.familyMsg', {
                          'name': p.name,
                          'dt': fmtNum(sc.maxDt, s.lang),
                          'side': t('side.${sc.warmerSide}'),
                        })),
                    icon: const Icon(Icons.chat_outlined),
                    label: Text(t('action.tellFamily')),
                  ),
                ],
                const SizedBox(height: 10),
                if (sc.acknowledgedAt == null)
                  OutlinedButton.icon(
                    onPressed: () => s.acknowledge(sc),
                    icon: const Icon(Icons.task_alt_rounded),
                    label: Text(t('action.ack')),
                  )
                else
                  InfoBanner(t('action.acked', {'when': ago(s, sc.acknowledgedAt)}), icon: Icons.task_alt_rounded),
                const SizedBox(height: QSpace.s3),
              ],
              _CareTeamCard(scan: sc),
              const SizedBox(height: QSpace.s3),
              Text(t('common.notDiagnosis'), style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
              const SizedBox(height: QSpace.s3),
              FilledButton(onPressed: () => Navigator.of(context).pop(), child: Text(t('common.done'))),
            ]),
          ),
        ],
      ),
    );
  }
}

/// Difference vs the 2.2 C threshold on a 0-4 C scale.
class _ThresholdBar extends StatelessWidget {
  final double value;
  final String level;
  const _ThresholdBar({required this.value, required this.level});

  @override
  Widget build(BuildContext context) {
    const max = 4.0;
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final x = (value.clamp(0, max) / max) * w;
      final th = (2.2 / max) * w;
      return Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          height: 34,
          child: Stack(clipBehavior: Clip.none, children: [
            Positioned(
              left: 0,
              right: 0,
              top: 8,
              child: Container(height: 10, decoration: BoxDecoration(color: QColors.sky100, borderRadius: BorderRadius.circular(99))),
            ),
            Positioned(
              left: 0,
              top: 8,
              child: Container(
                width: x,
                height: 10,
                decoration: BoxDecoration(color: QColors.level(level), borderRadius: BorderRadius.circular(99)),
              ),
            ),
            Positioned(left: th - 1, top: 2, child: Container(width: 2, height: 22, color: QColors.alert)),
            Positioned(
              left: th - 30,
              top: 24,
              child: const SizedBox(
                width: 60,
                child: Text('2,2 °C', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: QColors.alert)),
              ),
            ),
          ]),
        ),
      );
    });
  }
}

class _CareTeamCard extends StatelessWidget {
  final FootScan scan;
  const _CareTeamCard({required this.scan});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final t = s.t;
    final String text;
    IconData icon = Icons.local_hospital_outlined;
    BannerTone tone = BannerTone.info;
    if (!s.paired || !s.consentShare) {
      text = t('care.notShared');
      icon = Icons.phone_android_rounded;
    } else if (scan.reviewStatus == 'confirmed') {
      text = '${t('review.confirmed')}${scan.reviewNote != null ? ' — ${scan.reviewNote}' : ''}';
      icon = Icons.medical_services_outlined;
      tone = BannerTone.warn;
    } else if (scan.reviewStatus == 'dismissed') {
      text = '${t('review.dismissed')}${scan.reviewNote != null ? ' — ${scan.reviewNote}' : ''}';
      icon = Icons.medical_services_outlined;
    } else if (scan.hubLevel != null) {
      text = scan.level == 'green' ? t('care.received') : t('care.waitingReview');
    } else {
      text = t('care.pending');
      icon = Icons.cloud_upload_outlined;
    }
    return InfoBanner(text, icon: icon, tone: tone);
  }
}
