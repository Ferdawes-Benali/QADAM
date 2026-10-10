import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Two stylised feet coloured by status. The hot site is highlighted with a dot.
class FootStatusView extends StatelessWidget {
  final String status; // green | amber | red | none
  final String? hotSite; // hallux | mth1 | mth5 | heel
  final double size;
  const FootStatusView({super.key, required this.status, this.hotSite, this.size = 120});

  @override
  Widget build(BuildContext context) {
    final c = QadamColors.forStatus(status);
    Widget foot(bool mirror) => Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(mirror ? -1 : 1, 1, 1),
          child: SizedBox(
            width: size * 0.45,
            height: size,
            child: CustomPaint(painter: _FootPainter(c, mirror ? null : hotSite)),
          ),
        );
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [foot(true), SizedBox(width: size * 0.12), foot(false)]);
  }
}

class _FootPainter extends CustomPainter {
  final Color color;
  final String? hot;
  _FootPainter(this.color, this.hot);

  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()..color = color.withValues(alpha: 0.85);
    final sole = RRect.fromRectAndCorners(Rect.fromLTWH(s.width * 0.1, s.height * 0.18, s.width * 0.8, s.height * 0.8),
        topLeft: Radius.circular(s.width * 0.45), topRight: Radius.circular(s.width * 0.45),
        bottomLeft: Radius.circular(s.width * 0.4), bottomRight: Radius.circular(s.width * 0.4));
    canvas.drawRRect(sole, p);
    for (var i = 0; i < 5; i++) {
      final r = s.width * (i == 0 ? 0.14 : 0.08);
      canvas.drawCircle(Offset(s.width * (0.22 + i * 0.15), s.height * (0.1 + i * 0.02)), r, p);
    }
    if (hot != null) {
      final pos = {
        'hallux': Offset(s.width * 0.25, s.height * 0.1),
        'mth1': Offset(s.width * 0.3, s.height * 0.32),
        'mth5': Offset(s.width * 0.75, s.height * 0.38),
        'heel': Offset(s.width * 0.5, s.height * 0.88),
      }[hot];
      if (pos != null) {
        canvas.drawCircle(pos, s.width * 0.13, Paint()..color = Colors.white);
        canvas.drawCircle(pos, s.width * 0.09, Paint()..color = QadamColors.alert);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FootPainter old) => old.color != color || old.hot != hot;
}
