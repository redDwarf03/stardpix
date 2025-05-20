import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stardpix/application/current_color.dart';
import 'package:stardpix/application/pixels_canvas.dart';
import 'package:stardpix/ui/views/layer/bloc/provider.dart';
import 'package:stardpix/ui/views/layer/layouts/components/my_painter.dart';

class CanvasViewer extends ConsumerStatefulWidget {
  const CanvasViewer({
    super.key,
  });

  @override
  ConsumerState<CanvasViewer> createState() => _CanvasViewerState();
}

class _CanvasViewerState extends ConsumerState<CanvasViewer> {
  Offset? _cursorPosition;
  late TransformationController _transformationController;
  final canvasSize = const Size(3000, 1000);

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerAndScaleViewer();
    });
  }

  void _centerAndScaleViewer() {
    final viewportSize = MediaQuery.of(context).size;

    final scaleX = viewportSize.width / canvasSize.width;
    final scaleY = viewportSize.height / canvasSize.height;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    final offsetX = (viewportSize.width - canvasSize.width * scale) / 2;
    final offsetY = (viewportSize.height - canvasSize.height * scale) / 2;

    _transformationController.value = Matrix4.identity()
      ..scale(scale)
      ..translate(offsetX / scale, offsetY / scale);
  }

  void _updateCursorPosition(PointerEvent event) {
    setState(() {
      _cursorPosition = event.localPosition;
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Color? _getColorAtPosition(Offset position) {
    final pixelsPending = ref.read(LayerFormProvider.layerForm).pendingPixels;

    final pixels = ref.read(PixelCanvasProviders.pixelCanvasProvider);
    final dx = (position.dx / 10).floor();
    final dy = (position.dy / 10).floor();

    try {
      if (pixelsPending.contains((pixel) => pixel.dx == dx && pixel.dy == dy) ==
          true) {
        final pixelPending = pixelsPending
            .firstWhere((pixel) => pixel.dx == dx && pixel.dy == dy);
        return pixelPending.color;
      }

      final pixel =
          pixels.firstWhere((pixel) => pixel.dx == dx && pixel.dy == dy);
      return pixel.color;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final pickColor = ref.watch(LayerFormProvider.layerForm).pickColor;

    return Stack(
      children: [
        if (_cursorPosition != null)
          Positioned(
            top: 0,
            child: Container(
              color: Colors.transparent,
              padding: const EdgeInsets.all(4),
              child: Text(
                'Position: (${(_cursorPosition!.dx / 10).floor()}, ${(_cursorPosition!.dy / 10).floor()})',
                style: const TextStyle(fontSize: 10, color: Colors.black),
              ),
            ),
          ),
        InteractiveViewer(
          constrained: false,
          minScale: 0.0001,
          maxScale: 20,
          transformationController: _transformationController,
          boundaryMargin: const EdgeInsets.only(
            left: 100,
            right: 100,
            top: 2500,
            bottom: 2500,
          ),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.blue,
              ),
            ),
            width: canvasSize.width,
            height: canvasSize.height,
            child: GestureDetector(
              onDoubleTapDown: (event) async {
                if (pickColor) {
                  final newColor = _getColorAtPosition(event.localPosition);
                  if (newColor != null) {
                    ref
                        .read(
                          CurrentColorProviders.currentColorProvider.notifier,
                        )
                        .setColor(newColor);
                    ref
                        .read(LayerFormProvider.layerForm.notifier)
                        .setPickColor(false, ref);
                  }
                  return;
                }

                final timeLockInSeconds =
                    ref.read(LayerFormProvider.layerForm).timeLockInSeconds;
                if (timeLockInSeconds > 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    _displaySnackbar(
                      context,
                      AppLocalizations.of(context)!.waitForTimer,
                    ),
                  );
                  return;
                }

                final layer = ref.read(LayerFormProvider.layerForm);
                if (layer.isBuyProcess ||
                    layer.displayAbout ||
                    layer.displayColorPicker ||
                    layer.createInProgress) {
                  return;
                }

                final layerNotifier =
                    ref.read(LayerFormProvider.layerForm.notifier);

                final color =
                    ref.read(CurrentColorProviders.currentColorProvider);

                final result = await layerNotifier.addPendingPixels(
                  (_cursorPosition!.dx / 10).floor(),
                  (_cursorPosition!.dy / 10).floor(),
                  color,
                  ref,
                );

                if (result == false) {
                  final layerError = ref.read(LayerFormProvider.layerForm);
                  ScaffoldMessenger.of(context).showSnackBar(
                    _displaySnackbar(
                      context,
                      layerError.errorText,
                    ),
                  );
                  return;
                }
              },
              child: MouseRegion(
                onHover: _updateCursorPosition,
                child: CustomPaint(
                  size: const Size(3000, 1000),
                  painter: MyPainter(
                    ref: ref,
                    cursorPosition: _cursorPosition,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

SnackBar _displaySnackbar(BuildContext context, String text) {
  return SnackBar(
    backgroundColor: Colors.orangeAccent,
    content: Text(
      text,
      style: const TextStyle(
        color: Colors.black87,
      ),
    ),
    duration: const Duration(seconds: 2),
  );
}
