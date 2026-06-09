import 'package:flutter/material.dart';

class PlayerTokenViewer extends StatelessWidget {
  final String hexColor;
  final double size;
  final bool isSelected;

  const PlayerTokenViewer({
    super.key,
    required this.hexColor,
    this.size = 60,
    this.isSelected = false,
  });

  Color _parseHex(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final color = _parseHex(hexColor);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _TokenPainter(color: color, isSelected: isSelected),
      ),
    );
  }
}

class _TokenPainter extends CustomPainter {
  final Color color;
  final bool isSelected;

  const _TokenPainter({required this.color, required this.isSelected});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.38;

    // Sombra
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + r * 0.3), width: r * 1.6, height: r * 0.5),
      shadowPaint,
    );

    // Cuerpo del token (cilindro visto desde arriba)
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        radius: 0.9,
        colors: [
          Color.lerp(color, Colors.white, 0.4)!,
          color,
          Color.lerp(color, Colors.black, 0.4)!,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));

    canvas.drawCircle(Offset(cx, cy), r, bodyPaint);

    // Borde metálico
    final borderPaint = Paint()
      ..color = isSelected
          ? Colors.amber
          : Color.lerp(color, Colors.white, 0.6)!
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.5 : 1.5;
    canvas.drawCircle(Offset(cx, cy), r, borderPaint);

    // Brillo superior
    final shinePaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(Offset(cx - r * 0.25, cy - r * 0.25), r * 0.3, shinePaint);

    // Ring de selección animado
    if (isSelected) {
      final ringPaint = Paint()
        ..color = Colors.amber.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(Offset(cx, cy), r + 5, ringPaint);
    }
  }

  @override
  bool shouldRepaint(_TokenPainter old) =>
      old.color != color || old.isSelected != isSelected;
}