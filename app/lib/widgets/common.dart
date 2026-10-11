import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/tokens.dart';
import '../state/app_state.dart';

/// Shorthand: translated string for the current language.
String tr(BuildContext context, String key, [Map<String, String>? args]) =>
    context.read<AppState>().t(key, args);

/// Health status is always shape + word + colour (never colour alone):
/// circle = normal, triangle = to watch, square = alert.
class LevelBadge extends StatelessWidget {
  final String level; // green | amber | red | none
  final bool large;
  const LevelBadge(this.level, {super.key, this.large = false});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final label = s.t('level.$level');
    final size = large ? 16.0 : 11.0;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      LevelShape(level, size: size),
      SizedBox(width: large ? 10 : 6),
      Flexible(
        child: Text(label,
            style: TextStyle(
              color: QColors.levelText(level),
              fontWeight: FontWeight.w600,
              fontSize: large ? 22 : 14,
            )),
      ),
    ]);
  }
}

class LevelShape extends StatelessWidget {
  final String level;
  final double size;
  const LevelShape(this.level, {super.key, this.size = 11});

  @override
  Widget build(BuildContext context) =>
      SizedBox(width: size, height: size, child: CustomPaint(painter: _ShapePainter(level)));
}

class _ShapePainter extends CustomPainter {
  final String level;
  _ShapePainter(this.level);
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()..color = QColors.level(level);
    switch (level) {
      case 'green':
        canvas.drawCircle(s.center(Offset.zero), s.width / 2, p);
      case 'amber':
        canvas.drawPath(
            Path()
              ..moveTo(s.width / 2, 0)
              ..lineTo(s.width, s.height)
              ..lineTo(0, s.height)
              ..close(),
            p);
      case 'red':
        canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(2)), p);
      default:
        canvas.drawCircle(
            s.center(Offset.zero),
            s.width / 2 - 1,
            Paint()
              ..color = QColors.ink3
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5);
    }
  }

  @override
  bool shouldRepaint(covariant _ShapePainter old) => old.level != level;
}

/// Where a measurement comes from. Simulated data is never shown without this label.
class SourceBadge extends StatelessWidget {
  final String source; // hardware | simulated | manual | synthetic
  const SourceBadge(this.source, {super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final sim = source == 'simulated';
    final hw = source == 'hardware';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: hw ? QColors.navy900 : QColors.simBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: hw ? QColors.navy900 : const Color(0xFFB9C0CA)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(hw ? Icons.sensors_rounded : (sim ? Icons.science_outlined : Icons.edit_note_rounded),
            size: 15, color: hw ? const Color(0xFF5FD39A) : QColors.sim),
        const SizedBox(width: 5),
        Text(s.t('source.$source'),
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: hw ? Colors.white : QColors.sim,
              letterSpacing: sim ? 0.6 : 0,
            )),
      ]),
    );
  }
}

class SectionCard extends StatelessWidget {
  final String? title;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  const SectionCard({super.key, this.title, this.trailing, required this.child, this.padding = const EdgeInsets.all(QSpace.s4), this.onTap});

  @override
  Widget build(BuildContext context) {
    final body = Padding(
      padding: padding,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (title != null) ...[
          Row(children: [
            Expanded(child: Text(title!, style: Theme.of(context).textTheme.titleMedium)),
            if (trailing != null) trailing!,
          ]),
          const SizedBox(height: QSpace.s3),
        ],
        child,
      ]),
    );
    return Card(
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? body : InkWell(onTap: onTap, child: body),
    );
  }
}

enum BannerTone { info, warn, alert, sim }

class InfoBanner extends StatelessWidget {
  final String text;
  final IconData icon;
  final BannerTone tone;
  final Widget? action;
  const InfoBanner(this.text, {super.key, this.icon = Icons.info_outline_rounded, this.tone = BannerTone.info, this.action});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (tone) {
      BannerTone.warn => (QColors.watchBg, QColors.watch, const Color(0xFFF1D9A8)),
      BannerTone.alert => (QColors.alertBg, QColors.alert, const Color(0xFFF4C3BE)),
      BannerTone.sim => (QColors.simBg, QColors.sim, const Color(0xFFD0D5DD)),
      BannerTone.info => (QColors.sky50, QColors.ink2, QColors.sky200),
    };
    return Container(
      padding: const EdgeInsets.all(QSpace.s3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(QRadius.sm), border: Border.all(color: border)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 20, color: fg),
        const SizedBox(width: QSpace.s2),
        Expanded(child: Text(text, style: TextStyle(color: tone == BannerTone.info ? QColors.ink2 : fg, fontSize: 14.5, height: 1.4))),
        if (action != null) action!,
      ]),
    );
  }
}

class Metric extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final Color? color;
  const Metric({super.key, required this.label, required this.value, this.unit, this.color});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 2),
        Text.rich(TextSpan(children: [
          TextSpan(
              text: value,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600, color: color ?? QColors.ink, height: 1.15)),
          if (unit != null) TextSpan(text: ' $unit', style: const TextStyle(fontSize: 15, color: QColors.ink2)),
        ])),
      ]);
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Widget? action;
  const EmptyState({super.key, required this.icon, required this.title, required this.body, this.action});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: QSpace.s5, horizontal: QSpace.s4),
        child: Column(children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(color: QColors.sky100, shape: BoxShape.circle),
            child: Icon(icon, color: QColors.navy700, size: 28),
          ),
          const SizedBox(height: QSpace.s3),
          Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: QSpace.s1),
          Text(body, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
          if (action != null) ...[const SizedBox(height: QSpace.s4), action!],
        ]),
      );
}

class BrandLogo extends StatelessWidget {
  final double width;
  const BrandLogo({super.key, this.width = 140});
  @override
  Widget build(BuildContext context) =>
      Image.asset('assets/brand/qadam_logo.png', width: width, semanticLabel: 'Qadam — قدم', filterQuality: FilterQuality.medium);
}

/// "il y a 3 min" style relative time.
String ago(AppState s, DateTime? t) {
  if (t == null) return s.t('time.never');
  final d = DateTime.now().difference(t);
  if (d.inSeconds < 60) return s.t('time.s', {'n': '${d.inSeconds < 0 ? 0 : d.inSeconds}'});
  if (d.inMinutes < 60) return s.t('time.m', {'n': '${d.inMinutes}'});
  if (d.inHours < 24) return s.t('time.h', {'n': '${d.inHours}'});
  return s.t('time.d', {'n': '${d.inDays}'});
}

String fmtNum(double v, String lang, [int digits = 1]) {
  final x = v.toStringAsFixed(digits);
  return lang == 'fr' ? x.replaceAll('.', ',') : x;
}

String fmtDay(DateTime t) =>
    '${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')} ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// Small helper for headings inside scroll views.
class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, QSpace.s4, 4, QSpace.s2),
        child: Text(text.toUpperCase(),
            style: const TextStyle(fontSize: 12.5, letterSpacing: 0.8, fontWeight: FontWeight.w600, color: QColors.ink3)),
      );
}
