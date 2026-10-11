import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/tokens.dart';
import '../../models/models.dart';
import '../../services/storage_service.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import 'about_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _changePin(BuildContext context, AppState s) async {
    final oldC = TextEditingController(), newC = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(s.t('set.changePin')),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          for (final (ctrl, label) in [(oldC, s.t('set.oldPin')), (newC, s.t('set.newPin'))]) ...[
            TextField(
              controller: ctrl,
              obscureText: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
              decoration: InputDecoration(labelText: label),
            ),
            const SizedBox(height: 10),
          ],
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(s.t('common.cancel'))),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(s.t('common.save'))),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    if (newC.text.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.t('pin.err.format'))));
      return;
    }
    final done = await StorageService.changePin(oldC.text, newC.text);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done ? s.t('set.pinChanged') : s.t('lock.wrong'))));
  }

  Future<void> _erase(BuildContext context, AppState s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        icon: const Icon(Icons.delete_forever_outlined, color: QColors.alert, size: 40),
        title: Text(s.t('set.erase.title')),
        content: Text(s.paired ? s.t('set.erase.bodyPaired') : s.t('set.erase.body')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(s.t('common.cancel'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: QColors.alert),
            onPressed: () => Navigator.pop(c, true),
            child: Text(s.t('set.erase.confirm')),
          ),
        ],
      ),
    );
    if (ok == true) await s.eraseEverything();
  }

  Future<void> _editProfile(BuildContext context, AppState s) async {
    final p = Profile.fromMap(s.profile!.toMap());
    final name = TextEditingController(text: p.name);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (c) => StatefulBuilder(
        builder: (c, setSt) => Padding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.of(c).viewInsets.bottom),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(s.t('set.profile'), style: Theme.of(c).textTheme.titleLarge),
            const SizedBox(height: 14),
            TextField(controller: name, decoration: InputDecoration(labelText: s.t('you.name'))),
            const SizedBox(height: 14),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final ty in const ['t1', 't2', 'gest', 'other'])
                ChoiceChip(label: Text(s.t('type.$ty')), selected: p.diabetesType == ty, onSelected: (_) => setSt(() => p.diabetesType = ty)),
            ]),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final x in const ['tablets', 'insulin', 'both', 'diet'])
                ChoiceChip(label: Text(s.t('treat.$x')), selected: p.treatment == x, onSelected: (_) => setSt(() => p.treatment = x)),
            ]),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: p.pastUlcer,
              onChanged: (v) => setSt(() => p.pastUlcer = v),
              title: Text(s.t('risk.q1')),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: p.numbness,
              onChanged: (v) => setSt(() => p.numbness = v),
              title: Text(s.t('risk.q2')),
            ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: () {
                if (name.text.trim().isNotEmpty) p.name = name.text.trim();
                s.saveProfile(p);
                Navigator.pop(c);
              },
              child: Text(s.t('common.save')),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final t = s.t;
    return Scaffold(
      appBar: AppBar(title: Text(t('set.title'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(QSpace.s4, 0, QSpace.s4, QSpace.s6),
        children: [
          SectionTitle(t('set.language')),
          Card(
            child: Column(children: [
              for (final l in const [('aeb', 'تونسي — Derja'), ('ar', 'العربية'), ('fr', 'Français')])
                ListTile(
                  title: Text(l.$2),
                  trailing: s.lang == l.$1 ? const Icon(Icons.check_rounded, color: QColors.navy700) : null,
                  onTap: () => s.setLang(l.$1),
                ),
            ]),
          ),
          SectionTitle(t('set.profile')),
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_outline_rounded),
              title: Text(s.profile?.name ?? ''),
              subtitle: Text('${t('type.${s.profile?.diabetesType ?? 't2'}')} · ${t('riskLabel.${s.profile?.footRisk ?? 'low'}')}'),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () => _editProfile(context, s),
            ),
          ),
          SectionTitle(t('set.privacy')),
          Card(
            child: Column(children: [
              SwitchListTile(
                value: s.consentShare,
                onChanged: (v) => s.setConsents(share: v),
                title: Text(t('consent.share.t')),
                subtitle: Text(t('set.shareHelp')),
              ),
              SwitchListTile(
                value: s.consentAi,
                onChanged: (v) => s.setConsents(ai: v),
                title: Text(t('consent.ai.t')),
                subtitle: Text(t('set.aiHelp')),
              ),
              ListTile(
                leading: const Icon(Icons.password_rounded),
                title: Text(t('set.changePin')),
                onTap: () => _changePin(context, s),
              ),
              ListTile(
                leading: const Icon(Icons.lock_outline_rounded),
                title: Text(t('set.lockNow')),
                onTap: s.lockNow,
              ),
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: Text(t('set.export')),
                subtitle: Text(t('set.exportHelp')),
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: s.exportJson()));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('set.exported'))));
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever_outlined, color: QColors.alert),
                title: Text(t('set.erase.title'), style: const TextStyle(color: QColors.alert)),
                onTap: () => _erase(context, s),
              ),
            ]),
          ),
          SectionTitle(t('set.display')),
          Card(
            child: SwitchListTile(
              value: s.advanced,
              onChanged: s.setAdvanced,
              title: Text(t('set.advanced')),
              subtitle: Text(t('set.advancedHelp')),
            ),
          ),
          const SizedBox(height: QSpace.s3),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: Text(t('about.title')),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AboutScreen())),
            ),
          ),
        ],
      ),
    );
  }
}
