import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/strings.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';

class MedsScreen extends StatelessWidget {
  const MedsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final t = s.t;
    final today = DateTime.now();
    return Scaffold(
      appBar: AppBar(title: Text(t(K.meds))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context, s),
        icon: const Icon(Icons.add),
        label: Text(t(K.addMed)),
      ),
      body: ListView(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text('7 j : ${s.adherencePct()} %', style: Theme.of(context).textTheme.titleMedium),
        ),
        for (final m in s.meds)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${m.name} ${m.dose}', style: Theme.of(context).textTheme.titleMedium),
                Wrap(spacing: 8, children: [
                  for (final time in m.times)
                    FilterChip(
                      label: Text(time),
                      selected: m.isTaken(today, time),
                      onSelected: m.isTaken(today, time)
                          ? null
                          : (_) {
                              m.markTaken(today, time);
                              s.saveMed(m);
                            },
                    ),
                ]),
              ]),
            ),
          ),
      ]),
    );
  }

  Future<void> _add(BuildContext context, AppState s) async {
    final name = TextEditingController(), dose = TextEditingController(), times = TextEditingController(text: '08:00, 20:00');
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(s.t(K.addMed)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Nom / الإسم')),
          TextField(controller: dose, decoration: const InputDecoration(labelText: 'Dose')),
          TextField(controller: times, decoration: const InputDecoration(labelText: 'Heures (08:00, 20:00)')),
        ]),
        actions: [FilledButton(onPressed: () => Navigator.pop(d, true), child: Text(s.t(K.save)))],
      ),
    );
    if (ok != true || name.text.trim().isEmpty) return;
    final list = times.text.split(',').map((e) => e.trim()).where((e) => RegExp(r'^\d{2}:\d{2}$').hasMatch(e)).toList();
    await s.saveMed(Medication(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.text.trim(),
      dose: dose.text.trim(),
      times: list.isEmpty ? ['08:00'] : list,
    ));
  }
}
