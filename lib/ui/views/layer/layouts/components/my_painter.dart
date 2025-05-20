import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stardpix/application/pixels_canvas.dart';
import 'package:stardpix/ui/views/layer/bloc/provider.dart';

class MyPainter extends CustomPainter {
  MyPainter({required this.ref, this.cursorPosition});
  final WidgetRef ref;
  final Offset? cursorPosition;

  @override
  void paint(Canvas canvas, Size size) {
    final pixels = ref.read(PixelCanvasProviders.pixelCanvasProvider);
    final layer = ref.watch(LayerFormProvider.layerForm);

    for (final pixel in pixels) {
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = pixel.color!;
      canvas.drawRect(
        Rect.fromLTWH(
          pixel.dx!.toDouble() * 10,
          pixel.dy!.toDouble() * 10,
          10,
          10,
        ),
        paint,
      );
    }

    for (final pixel in layer.pendingPixels) {
      if (pixel.isPendingPixel == true) {
        final pendingRect = Rect.fromLTWH(
          pixel.dx!.toDouble() * 10,
          pixel.dy!.toDouble() * 10,
          10,
          10,
        );
        final paint = Paint()
          ..style = PaintingStyle.fill
          ..color = pixel.color!;
        final borderPending = Paint()
          ..color = Colors.red
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

        canvas
          ..drawRect(pendingRect, paint)
          ..drawRect(pendingRect, borderPending);
      }
    }

    if (cursorPosition != null) {
      final previewPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..style = PaintingStyle.stroke;

      final previewRect = Rect.fromLTWH(
        (cursorPosition!.dx / 10).floorToDouble() * 10,
        (cursorPosition!.dy / 10).floorToDouble() * 10,
        10,
        10,
      );

      canvas
        ..drawRect(previewRect, previewPaint)
        ..drawRect(previewRect, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
