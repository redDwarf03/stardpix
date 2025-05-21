import 'package:flutter/material.dart';

class LoupeOverlay extends StatelessWidget {
  const LoupeOverlay({
    super.key,
    required this.position,
    required this.painter,
    this.loupeSize = 80,
    this.zoomLevel = 0,
  });
  final Offset position;
  final CustomPainter painter;
  final double loupeSize;
  final int zoomLevel;

  double get _zoom {
    switch (zoomLevel) {
      case 1:
        return 4;
      case 2:
        return 5;
      default:
        return 3;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loupeOffset = Offset(30, -loupeSize - 30);

    return Positioned(
      left: position.dx + loupeOffset.dx,
      top: position.dy + loupeOffset.dy,
      child: ClipOval(
        child: Container(
          width: loupeSize,
          height: loupeSize,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.deepPurple, width: 2),
            color: Colors.white,
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                spreadRadius: 2,
              ),
            ],
          ),
          child: CustomPaint(
            size: Size(loupeSize, loupeSize),
            painter: _LoupePainter(
              painter: painter,
              focus: position,
              loupeSize: loupeSize,
              zoom: _zoom,
            ),
          ),
        ),
      ),
    );
  }
}

class _LoupePainter extends CustomPainter {
  _LoupePainter({
    required this.painter,
    required this.focus,
    required this.loupeSize,
    required this.zoom,
  });
  final CustomPainter painter;
  final Offset focus;
  final double loupeSize;
  final double zoom;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..translate(
        -focus.dx * (zoom - 1) + size.width / 2 - 5,
        -focus.dy * (zoom - 1) + size.height / 2 - 5,
      )
      ..scale(zoom, zoom);
    painter.paint(canvas, const Size(3000, 1000));
    canvas.restore();
    // Optionnel : dessiner une croix au centre de la loupe
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = Colors.deepPurple
      ..strokeWidth = 1.5;
    canvas
      ..drawLine(
        center - const Offset(8, 0),
        center + const Offset(8, 0),
        paint,
      )
      ..drawLine(
        center - const Offset(0, 8),
        center + const Offset(0, 8),
        paint,
      );
  }

  @override
  bool shouldRepaint(covariant _LoupePainter oldDelegate) {
    return true;
  }
}
