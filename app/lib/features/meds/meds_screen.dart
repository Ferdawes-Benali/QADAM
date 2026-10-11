import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/tokens.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';

class MedsScreen extends StatelessWidget {
  const MedsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final t = s.t;
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(title: Text(t('meds.title'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, null),
        backgroundColor: QColors.navy700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(t('meds.add')),
      ),
      body: s.meds.isEmpty
          ? EmptyState(icon: Icons.medication_outlined, title: t('meds.empty.t'), body: t('meds.empty.b'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(QSpace.s4, 0, QSpace.s4, 110),
              children: [
                SectionCard(child: Metric(label: t('meds.adherence7'), value: '${s.adherencePct()}', unit: '%')),
                const SizedBox(height: QSpace.s2),
                InfoBanner(t('meds.note'), icon: Icons.info_outline_rounded),
                SectionTitle(t('meds.today')),
                for (final m in s.meds) ...[
                  SectionCard(
                    title: m.dose.isEmpty ? m.name : '${m.name} · ${m.dose}',
                    trailing: IconButton(
                      tooltip: t('common.edit'),
                      icon: const Icon(Icons.edit_outlined, color: QColors.ink2),
                      onPressed: () => _edit(context, m),
                    ),
                    child: Wrap(spacing: 10, runSpacing: 10, children: [
                      for (final tm in m.times)
                        FilterChip(
                          selected: m.isTaken(now, tm),
                          onSelected: (_) => s.toggleDose(m, tm),
                          avatar: Icon(m.isTaken(now, tm) ? Icons.check_circle_rounded : Icons.schedule_rounded,
                              size: 20, color: m.isTaken(now, tm) ? QColors.ok : QColors.ink2),
                          showCheckmark: false,
                          label: Text(m.isTaken(now, tm) ? '$tm · ${t('meds.taken')}' : tm),
                          selectedColor: QColors.okBg,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        ),
                    ]),
                  ),
                  const SizedBox(height: QSpace.s3),
                ],
              ],
            ),
    );
  }

  Future<void> _edit(BuildContext context, Medication? m) async {
    final s = context.read<AppState>();
    final res = await showModalBottomSheet<Object>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _MedSheet(existing: m),
    );
    if (res is Medication) await s.saveMed(res);
    if (res == 'delete' && m != null) await s.deleteMed(m);
  }
}

class _MedSheet extends StatefulWidget {
  final Medication? existing;
  const _MedSheet({this.existing});
  @override
  State<_MedSheet> createState() => _MedSheetState();
}

class _MedSheetState extends State<_MedSheet> {
  late final name = TextEditingController(text: widget.existing?.name ?? '');
  late final dose = TextEditingController(text: widget.existing?.dose ?? '');
  late final List<String> times = List<String>.from(widget.existing?.times ?? const ['08:00']);

  @override
  void dispose() {
    name.dispose();
    dose.dispose();
    super.dispose();
  }

  Future<void> _addTime() async {
    final picked = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 20, minute: 0));
    if (picked == null) return;
    final v = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    if (!times.contains(v)) setState(() => times..add(v)..sort());
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final t = s.t;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(widget.existing == null ? t('meds.add') : t('meds.edit'), style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        TextField(controller: name, decoration: InputDecoration(labelText: t('meds.name'), hintText: 'Metformine')),
        const SizedBox(height: 12),
        TextField(controller: dose, decoration: InputDecoration(labelText: t('meds.dose'), hintText: '850 mg')),
        const SizedBox(height: 16),
        Text(t('meds.times'), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final tm in times)
            InputChip(
              label: Text(tm),
              onDeleted: times.length > 1 ? () => setState(() => times.remove(tm)) : null,
            ),
          ActionChip(avatar: const Icon(Icons.add_rounded, size: 18), label: Text(t('meds.addTime')), onPressed: _addTime),
        ]),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () {
            if (name.text.trim().isEmpty) return;
            final m = widget.existing ?? Medication(id: newId(), name: '');
            m.name = name.text.trim();
            m.dose = dose.text.trim();
            m.times = times;
            Navigator.pop(context, m);
          },
          child: Text(t('common.save')),
        ),
        if (widget.existing != null) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context, 'delete'),
            style: TextButton.styleFrom(foregroundColor: QColors.alert),
            child: Text(t('common.delete')),
          ),
        ],
      ]),
    );
  }
}
