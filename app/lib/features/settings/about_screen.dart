import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/tokens.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final t = s.t;
    Widget block(IconData icon, String title, String body) => Padding(
          padding: const EdgeInsets.only(bottom: QSpace.s3),
          child: SectionCard(
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(icon, color: QColors.navy700),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(body, style: Theme.of(context).textTheme.bodyMedium),
                ]),
              ),
            ]),
          ),
        );
    return Scaffold(
      appBar: AppBar(title: Text(t('about.title'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(QSpace.s4, 0, QSpace.s4, QSpace.s6),
        children: [
          const Center(child: Padding(padding: EdgeInsets.all(16), child: BrandLogo(width: 170))),
          block(Icons.flag_outlined, t('about.use.t'), t('about.use.b')),
          block(Icons.science_outlined, t('about.proto.t'), t('about.proto.b')),
          block(Icons.rule_rounded, t('about.rule.t'), t('about.rule.b')),
          block(Icons.lock_outline_rounded, t('about.privacy.t'), t('about.privacy.b')),
          block(Icons.auto_awesome_outlined, t('about.ai.t'), t('about.ai.b')),
          block(Icons.gavel_outlined, t('about.reg.t'), t('about.reg.b')),
          const SizedBox(height: 8),
          Text('Qadam 1.0.0 · HackCure 2026', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
