import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/tokens.dart';
import '../../models/models.dart';
import '../../services/actions_service.dart';
import '../../services/safety_service.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';

/// Qadam assistant: education + reassurance, with a hard safety pipeline:
/// on-device red-flag rules -> (care team hub) Gemini grounded on the verified library -> verified library offline.
/// Every answer says where it comes from.
class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});
  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final input = TextEditingController();
  final scroll = ScrollController();

  @override
  void dispose() {
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> _send(AppState s, [String? text]) async {
    final q = (text ?? input.text).trim();
    if (q.isEmpty) return;
    input.clear();
    final f = s.ask(q);
    _toBottom();
    await f;
    _toBottom();
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scroll.hasClients) scroll.animateTo(scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    });
  }

  void _topic(AppState s, String id) {
    s.chat.add(ChatMessage(fromUser: true, text: s.t('topic.$id'), kind: 'question', source: 'user'));
    s.chat.add(ChatMessage(fromUser: false, text: SafetyService.topicAnswer(id, s.lang), kind: 'answer', source: 'library'));
    setState(() {});
    _toBottom();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final t = s.t;
    final online = s.paired && s.consentAi;
    return Scaffold(
      appBar: AppBar(
        title: Text(t('ai.title')),
        actions: [
          if (s.chat.isNotEmpty)
            IconButton(tooltip: t('ai.clear'), icon: const Icon(Icons.delete_sweep_outlined), onPressed: () => setState(s.chat.clear)),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(QSpace.s4, 0, QSpace.s4, QSpace.s2),
          child: InfoBanner(online ? t('ai.mode.online') : t('ai.mode.offline'),
              icon: online ? Icons.auto_awesome_outlined : Icons.menu_book_outlined),
        ),
        Expanded(
          child: s.chat.isEmpty
              ? ListView(padding: const EdgeInsets.all(QSpace.s4), children: [
                  Text(t('ai.intro'), style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: QSpace.s4),
                  Text(t('ai.topics'), style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: QSpace.s2),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final id in SafetyService.topicIds())
                      ActionChip(label: Text(t('topic.$id')), onPressed: () => _topic(s, id)),
                  ]),
                  const SizedBox(height: QSpace.s4),
                  InfoBanner(t('ai.limits'), icon: Icons.health_and_safety_outlined),
                ])
              : ListView.builder(
                  controller: scroll,
                  padding: const EdgeInsets.all(QSpace.s4),
                  itemCount: s.chat.length + (s.asking ? 1 : 0),
                  itemBuilder: (_, i) => i == s.chat.length ? const _Typing() : _Bubble(s.chat[i]),
                ),
        ),
        if (online)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: QSpace.s4),
            child: Row(children: [
              Expanded(child: Text(t('ai.shareContext'), style: Theme.of(context).textTheme.bodySmall)),
              Switch(value: s.shareContextWithAi, onChanged: (v) => s.setConsents(context: v)),
            ]),
          ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(QSpace.s4, 4, QSpace.s3, QSpace.s3),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: input,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 500,
                  textInputAction: TextInputAction.send,
                  decoration: InputDecoration(hintText: t('ai.hint'), counterText: ''),
                  onSubmitted: (_) => _send(s),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: t('ai.send'),
                onPressed: s.asking ? null : () => _send(s),
                icon: const Icon(Icons.send_rounded),
                style: IconButton.styleFrom(backgroundColor: QColors.navy700, minimumSize: const Size(52, 52)),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage m;
  const _Bubble(this.m);

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final t = s.t;
    if (m.fromUser) {
      return Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Container(
          margin: const EdgeInsetsDirectional.only(start: 48, bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
            color: QColors.navy700,
            borderRadius: BorderRadiusDirectional.only(
              topStart: Radius.circular(16),
              topEnd: Radius.circular(16),
              bottomStart: Radius.circular(16),
              bottomEnd: Radius.circular(4),
            ),
          ),
          child: Text(m.text, style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4)),
        ),
      );
    }
    final danger = m.kind == 'emergency' || m.kind == 'urgent';
    final (label, icon) = switch (m.source) {
      'rules' => (t('ai.src.rules'), Icons.shield_outlined),
      'gemini' => (t('ai.src.gemini'), Icons.auto_awesome_outlined),
      'library' => (t('ai.src.library'), Icons.menu_book_outlined),
      _ => (t('ai.src.offline'), Icons.menu_book_outlined),
    };
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsetsDirectional.only(end: 32, bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: danger ? QColors.alertBg : Colors.white,
          border: Border.all(color: danger ? const Color(0xFFF4C3BE) : QColors.line),
          borderRadius: const BorderRadiusDirectional.only(
            topStart: Radius.circular(16),
            topEnd: Radius.circular(16),
            bottomEnd: Radius.circular(16),
            bottomStart: Radius.circular(4),
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (danger)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                const Icon(Icons.emergency_outlined, color: QColors.alert),
                const SizedBox(width: 6),
                Flexible(
                    child: Text(t('ai.danger.${m.kind}'),
                        style: const TextStyle(color: QColors.alert, fontWeight: FontWeight.w700))),
              ]),
            ),
          Text(m.text, style: const TextStyle(fontSize: 16, height: 1.45, color: QColors.ink)),
          if (m.kind == 'emergency') ...[
            const SizedBox(height: 10),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: QColors.alert),
              onPressed: ActionsService.callEmergency,
              icon: const Icon(Icons.call_rounded),
              label: Text(t('action.call190')),
            ),
          ],
          if (m.kind == 'urgent' && (s.profile?.doctorPhone ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => ActionsService.call(s.profile!.doctorPhone),
              icon: const Icon(Icons.call_rounded),
              label: Text(t('action.callDoctor', {'name': s.profile!.doctorName})),
            ),
          ],
          const SizedBox(height: 8),
          Row(children: [
            Icon(icon, size: 14, color: QColors.ink3),
            const SizedBox(width: 4),
            Flexible(child: Text(label, style: const TextStyle(fontSize: 12, color: QColors.ink3))),
          ]),
        ]),
      ),
    );
  }
}

class _Typing extends StatelessWidget {
  const _Typing();
  @override
  Widget build(BuildContext context) => const Align(
        alignment: AlignmentDirectional.centerStart,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2.5)),
        ),
      );
}
