import 'package:flutter/material.dart';

import 'package:renti/core/theme/app_theme.dart';

/// Casita con punto naranja (logo de Renti).
class RentiLogo extends StatelessWidget {
  final double size;
  final Color color;
  const RentiLogo({super.key, this.size = 90, this.color = Colors.white});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size(size, size), painter: _LogoPainter(color));
}

class _LogoPainter extends CustomPainter {
  final Color color;
  _LogoPainter(this.color);

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width;
    final stroke = w * 0.14;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(w * 0.12, w * 0.92)
      ..lineTo(w * 0.12, w * 0.46)
      ..lineTo(w * 0.5, w * 0.08)
      ..lineTo(w * 0.88, w * 0.46)
      ..lineTo(w * 0.88, w * 0.92);
    canvas.drawPath(path, paint);
    canvas.drawCircle(Offset(w * 0.78, w * 0.8), w * 0.11, Paint()..color = RentiColors.orange);
  }

  @override
  bool shouldRepaint(covariant _LogoPainter old) => old.color != color;
}

/// Logo en cuadro azul redondeado (cabecera de bienvenida).
class RentiAppIcon extends StatelessWidget {
  final double size;
  const RentiAppIcon({super.key, this.size = 38});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: RentiColors.blue,
          borderRadius: BorderRadius.circular(size * 0.28),
        ),
        alignment: Alignment.center,
        child: RentiLogo(size: size * 0.6),
      );
}
