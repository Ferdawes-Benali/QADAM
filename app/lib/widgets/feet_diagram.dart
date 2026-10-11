import 'package:flutter/material.dart';

import '../core/tokens.dart';

/// Top view of both feet standing on the mat. Measured sites are dots; the warmer site of an amber/red scan
/// is drawn larger, in the status colour, with a ring. Left foot on the left of the screen (as the patient sees it).
class FeetDiagram extends StatelessWidget {
  final Set<String> sites; // measured sites, e.g. {'mth1'} for the 2-sensor bench
  final String? hotSite;
  final String? warmerSide; // left | right
  final String level; // green | amber | red | none
  final double height;
  final String semanticLabel;

  const FeetDiagram({
    super.key,
    this.sites = const {'mth1'},
    this.hotSite,
    this.warmerSide,
    this.level = 'none',
    this.height = 180,
    this.semanticLabel = '',
  });

  @override
  Widget build(BuildContext context) {
    final w = height * 0.42;
    Widget foot(bool isLeft) => SizedBox(
          width: w,
          height: height,
          child: CustomPaint(
            painter: _FootPainter(
              mirror: isLeft,
              sites: sites,
              hot: (level == 'amber' || level == 'red') && warmerSide == (isLeft ? 'left' : 'right') ? hotSite : null,
              hotColor: QColors.level(level),
            ),
          ),
        );
    return Semantics(
      label: semanticLabel,
      child: Directionality(
        textDirection: TextDirection.ltr, // anatomy does not flip in RTL layouts
        child: Row(mainAxisSize: MainAxisSize.min, children: [foot(true), SizedBox(width: w * 0.35), foot(false)]),
      ),
    );
  }
}

class _FootPainter extends CustomPainter {
  final bool mirror;
  final Set<String> sites;
  final String? hot;
  final Color hotColor;
  _FootPainter({required this.mirror, required this.sites, required this.hot, required this.hotColor});

  static const _sitePos = {
    'hallux': Offset(0.25, 0.125),
    'mth1': Offset(0.28, 0.33),
    'mth5': Offset(0.76, 0.35),
    'heel': Offset(0.52, 0.86),
  };

  Offset _p(Size s, double x, double y) => Offset((mirror ? 1 - x : x) * s.width, y * s.height);

  @override
  void paint(Canvas canvas, Size s) {
    // right foot outline (medial side = left of the drawing); mirrored for the left foot
    final path = Path()
      ..moveTo(_p(s, 0.55, 0.985).dx, _p(s, 0.55, 0.985).dy);
    void cubic(double x1, double y1, double x2, double y2, double x, double y) {
      final a = _p(s, x1, y1), b = _p(s, x2, y2), c = _p(s, x, y);
      path.cubicTo(a.dx, a.dy, b.dx, b.dy, c.dx, c.dy);
    }

    cubic(0.32, 0.99, 0.20, 0.95, 0.20, 0.85);
    cubic(0.20, 0.72, 0.12, 0.60, 0.13, 0.45);
    cubic(0.13, 0.36, 0.08, 0.30, 0.10, 0.25);
    cubic(0.16, 0.15, 0.78, 0.15, 0.90, 0.28);
    cubic(0.97, 0.42, 0.88, 0.62, 0.82, 0.80);
    cubic(0.78, 0.93, 0.66, 0.99, 0.55, 0.985);
    path.close();

    final fill = Paint()..color = QColors.sky100;
    final stroke = Paint()
      ..color = QColors.sky400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
    const toes = [
      (0.25, 0.125, 0.105),
      (0.44, 0.115, 0.068),
      (0.59, 0.13, 0.06),
      (0.72, 0.16, 0.054),
      (0.83, 0.205, 0.047),
    ];
    for (final t in toes) {
      final c = _p(s, t.$1, t.$2);
      canvas.drawCircle(c, s.width * t.$3, fill);
      canvas.drawCircle(c, s.width * t.$3, stroke);
    }

    for (final site in sites) {
      final rel = _sitePos[site];
      if (rel == null) continue;
      final c = _p(s, rel.dx, rel.dy);
      if (site == hot) {
        canvas.drawCircle(c, s.width * 0.17, Paint()..color = hotColor.withValues(alpha: 0.25));
        canvas.drawCircle(c, s.width * 0.11, Paint()..color = hotColor);
        canvas.drawCircle(
            c,
            s.width * 0.11,
            Paint()
              ..color = Colors.white
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2);
      } else {
        canvas.drawCircle(c, s.width * 0.065, Paint()..color = QColors.navy700);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FootPainter old) =>
      old.hot != hot || old.hotColor != hotColor || old.mirror != mirror || old.sites != sites;
}
