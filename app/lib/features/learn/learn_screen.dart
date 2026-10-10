import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/diabetes_content.dart';
import '../../core/strings.dart';
import '../../services/gemini_service.dart';
import '../../state/app_state.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});
  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  final _q = TextEditingController();
  final _chat = <(String, String)>[]; // (role, text)
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final t = s.t;
    final p = s.profile!;
    return Column(children: [
      Expanded(
        child: ListView(padding: const EdgeInsets.only(bottom: 12), children: [
          Padding(padding: const EdgeInsets.all(20), child: Text(t(K.learn), style: Theme.of(context).textTheme.headlineSmall)),
          Card(child: ExpansionTile(
            leading: const Icon(Icons.info_rounded),
            title: Text(t(K.myDiabetes)),
            initiallyExpanded: true,
            children: [Padding(padding: const EdgeInsets.all(16), child: Text(diabetesTypeInfo[p.diabetesType] ?? ''))],
          )),
          Card(child: ExpansionTile(
            leading: const Icon(Icons.directions_walk_rounded),
            title: const Text('Soins des pieds / العناية بالساقين'),
            children: [Padding(padding: const EdgeInsets.all(16), child: Text(footCareBasics))],
          )),
          for (final m in _chat)
            Align(
              alignment: m.$1 == 'me' ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.all(12),
                constraints: const BoxConstraints(maxWidth: 320),
                decoration: BoxDecoration(
                  color: m.$1 == 'me' ? Theme.of(context).colorScheme.primaryContainer : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(m.$2, style: const TextStyle(fontSize: 16)),
              ),
            ),
          if (_busy) const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Expanded(child: TextField(controller: _q, decoration: InputDecoration(hintText: t(K.askHint), labelText: t(K.askCoach)))),
          IconButton.filled(
            icon: const Icon(Icons.send_rounded),
            onPressed: _busy
                ? null
                : () async {
                    final q = _q.text.trim();
                    if (q.isEmpty) return;
                    setState(() { _chat.add(('me', q)); _busy = true; _q.clear(); });
                    final a = await GeminiService().coach(q, p, s.lang);
                    if (mounted) setState(() { _chat.add(('ai', a)); _busy = false; });
                  },
          ),
        ]),
      ),
    ]);
  }
}
