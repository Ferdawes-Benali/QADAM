import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/tokens.dart';
import '../../models/models.dart';
import '../../services/actions_service.dart';
import '../../services/report_service.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../settings/connection_screen.dart';

/// Care circle: doctor, family, care team link, and the PDF report for the consultation.
class CareScreen extends StatefulWidget {
  const CareScreen({super.key});
  @override
  State<CareScreen> createState() => _CareScreenState();
}

class _CareScreenState extends State<CareScreen> {
  bool building = false;

  Future<void> _editContact(AppState s, {required bool doctor}) async {
    final p = s.profile!;
    final name = TextEditingController(text: doctor ? p.doctorName : p.familyName);
    final phone = TextEditingController(text: doctor ? p.doctorPhone : p.familyPhone);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(s.t(doctor ? 'contacts.doctor' : 'contacts.family')),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: InputDecoration(labelText: s.t('contacts.name'))),
          const SizedBox(height: 12),
          TextField(
            controller: phone,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(labelText: s.t('contacts.phone'), hintText: '216 98 000 000'),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(s.t('common.cancel'))),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(s.t('common.save'))),
        ],
      ),
    );
    if (ok == true) {
      final np = Profile.fromMap(p.toMap());
      if (doctor) {
        np.doctorName = name.text.trim();
        np.doctorPhone = phone.text.trim();
      } else {
        np.familyName = name.text.trim();
        np.familyPhone = phone.text.trim();
      }
      await s.saveProfile(np);
    }
    // controllers are not disposed here: the dialog may still be animating out (they are garbage-collected)
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final t = s.t;
    final p = s.profile!;

    Widget contact({required bool doctor}) {
      final name = doctor ? p.doctorName : p.familyName;
      final phone = doctor ? p.doctorPhone : p.familyPhone;
      return SectionCard(
        title: t(doctor ? 'contacts.doctor' : 'contacts.family'),
        trailing: IconButton(
          tooltip: t('common.edit'),
          icon: const Icon(Icons.edit_outlined, color: QColors.ink2),
          onPressed: () => _editContact(s, doctor: doctor),
        ),
        child: phone.isEmpty
            ? Text(t('care.noContact'), style: Theme.of(context).textTheme.bodyMedium)
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(name.isEmpty ? phone : '$name · $phone', style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => ActionsService.call(phone),
                      icon: const Icon(Icons.call_rounded),
                      label: Text(t('care.call')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => ActionsService.whatsapp(phone, t('care.hello', {'name': p.name})),
                      icon: const Icon(Icons.chat_outlined),
                      label: const Text('WhatsApp'),
                    ),
                  ),
                ]),
              ]),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(t('care.title'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(QSpace.s4, 0, QSpace.s4, QSpace.s6),
        children: [
          contact(doctor: true),
          const SizedBox(height: QSpace.s3),
          contact(doctor: false),
          const SizedBox(height: QSpace.s3),
          SectionCard(
            title: t('care.team'),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(
                s.paired ? t('care.paired', {'ref': s.patientRef ?? ''}) : t('care.notPaired'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ConnectionScreen())),
                child: Text(s.paired ? t('care.manage') : t('care.connect')),
              ),
            ]),
          ),
          const SizedBox(height: QSpace.s3),
          SectionCard(
            title: t('care.report'),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(t('care.reportBody'), style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: building
                    ? null
                    : () async {
                        setState(() => building = true);
                        try {
                          await ReportService.share(
                            profile: p,
                            patientRef: s.patientRef,
                            glucose: s.glucose,
                            scans: s.scans,
                            adherencePct: s.adherencePct(),
                          );
                        } finally {
                          if (mounted) setState(() => building = false);
                        }
                      },
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: Text(t('care.reportBtn')),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
