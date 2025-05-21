import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stardpix/application/current_color.dart';
import 'package:stardpix/application/pixels_canvas.dart';
import 'package:stardpix/ui/views/layer/bloc/provider.dart';
import 'package:stardpix/ui/views/layer/layouts/components/loupe_overlay.dart';
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
  static const int pixelCountX = 300;
  static const int pixelCountY = 100;
  static const double pixelSizeDefault = 10;
  static const double pixelSizeLarge = 20;

  bool _hasShownNotEnoughPixError = false;
  Offset? _loupePosition;
  bool _showLoupe = false;

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
    final zoomLevel = ref.read(LayerFormProvider.layerForm).zoomLevel;

    double pixelSize;
    switch (zoomLevel) {
      case 1:
        pixelSize = pixelSizeLarge;
        break;
      case 2:
        pixelSize = pixelSizeLarge * 1.5;
        break;
      default:
        pixelSize = pixelSizeDefault;
        break;
    }

    final canvasSize = Size(pixelCountX * pixelSize, pixelCountY * pixelSize);

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

  void _showLoupeAt(Offset pos) {
    setState(() {
      _loupePosition = pos;
      _showLoupe = true;
    });
  }

  void _hideLoupe() {
    setState(() {
      _showLoupe = false;
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
    final layerState = ref.watch(LayerFormProvider.layerForm);
    final pickColor = layerState.pickColor;
    final zoomLevel = layerState.zoomLevel;

    double pixelSize;
    switch (zoomLevel) {
      case 1:
        pixelSize = pixelSizeLarge;
        break;
      case 2:
        pixelSize = pixelSizeLarge * 1.5;
        break;
      default:
        pixelSize = pixelSizeDefault;
        break;
    }

    final canvasSize = Size(pixelCountX * pixelSize, pixelCountY * pixelSize);

    return Stack(
      children: [
        Container(color: Colors.black),
        Padding(
          padding: const EdgeInsets.all(10),
          child: InteractiveViewer(
            constrained: false,
            minScale: 0.0001,
            maxScale: 20,
            transformationController: _transformationController,
            boundaryMargin: EdgeInsets.only(
              left: 100,
              right: 100,
              top: canvasSize.height * 2.5,
              bottom: canvasSize.height * 2.5,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: Colors.blue,
                ),
              ),
              width: canvasSize.width,
              height: canvasSize.height,
              child: Builder(
                builder: (context) {
                  final quickDrawMode =
                      ref.watch(LayerFormProvider.layerForm).quickDrawMode;
                  if (quickDrawMode) {
                    return GestureDetector(
                      onPanDown: (details) {
                        _showLoupeAt(details.localPosition);
                      },
                      onPanUpdate: (details) {
                        _showLoupeAt(details.localPosition);
                      },
                      onPanEnd: (_) {
                        _hideLoupe();
                      },
                      onTapUp: (_) {
                        _hideLoupe();
                      },
                      onTapCancel: _hideLoupe,
                      onDoubleTapDown: (event) async {
                        if (pickColor) {
                          final newColor =
                              _getColorAtPosition(event.localPosition);
                          if (newColor != null) {
                            ref
                                .read(
                                  CurrentColorProviders
                                      .currentColorProvider.notifier,
                                )
                                .setColor(newColor);
                            ref
                                .read(LayerFormProvider.layerForm.notifier)
                                .setPickColor(false, ref);
                          }
                          return;
                        }

                        final timeLockInSeconds = ref
                            .read(LayerFormProvider.layerForm)
                            .timeLockInSeconds;
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
                            layer.isWalletProcess ||
                            layer.displayAbout ||
                            layer.displayColorPicker ||
                            layer.createInProgress) {
                          return;
                        }

                        final layerNotifier =
                            ref.read(LayerFormProvider.layerForm.notifier);

                        final color = ref
                            .read(CurrentColorProviders.currentColorProvider);

                        final result = await layerNotifier.addPendingPixels(
                          (event.localPosition.dx / 10).floor(),
                          (event.localPosition.dy / 10).floor(),
                          color,
                          ref,
                        );

                        if (result == false) {
                          final layerError =
                              ref.read(LayerFormProvider.layerForm);
                          ScaffoldMessenger.of(context).showSnackBar(
                            _displaySnackbar(
                              context,
                              layerError.errorText,
                            ),
                          );
                          return;
                        }
                      },
                      onPanStart: (details) async {
                        _hasShownNotEnoughPixError =
                            false; // reset at start of drag
                        if (_hasShownNotEnoughPixError) return;

                        final layer = ref.read(LayerFormProvider.layerForm);
                        if (layer.isBuyProcess ||
                            layer.displayAbout ||
                            layer.displayColorPicker ||
                            layer.createInProgress) {
                          return;
                        }

                        final timeLockInSeconds = layer.timeLockInSeconds;
                        if (timeLockInSeconds > 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            _displaySnackbar(
                              context,
                              AppLocalizations.of(context)!.waitForTimer,
                            ),
                          );
                          return;
                        }

                        final color = ref
                            .read(CurrentColorProviders.currentColorProvider);

                        final layerNotifier =
                            ref.read(LayerFormProvider.layerForm.notifier);

                        final result = await layerNotifier.addPendingPixels(
                          (details.localPosition.dx / 10).floor(),
                          (details.localPosition.dy / 10).floor(),
                          color,
                          ref,
                        );

                        if (result == false) {
                          final layerError =
                              ref.read(LayerFormProvider.layerForm);
                          if (!_hasShownNotEnoughPixError &&
                              layerError.errorText ==
                                  "you don't have enough PIX") {
                            _hasShownNotEnoughPixError = true;
                            ScaffoldMessenger.of(context).showSnackBar(
                              _displaySnackbar(
                                context,
                                layerError.errorText,
                              ),
                            );
                          }
                          return;
                        }
                      },
                      child: MouseRegion(
                        onHover: _updateCursorPosition,
                        child: CustomPaint(
                          size: canvasSize,
                          painter: MyPainter(
                            ref: ref,
                            cursorPosition: _cursorPosition,
                          ),
                        ),
                      ),
                    );
                  } else {
                    // Mode normal : pas de handlers, juste double-tap pour pickColor/pose classique
                    return GestureDetector(
                      onDoubleTapDown: (event) async {
                        if (pickColor) {
                          final newColor =
                              _getColorAtPosition(event.localPosition);
                          if (newColor != null) {
                            ref
                                .read(
                                  CurrentColorProviders
                                      .currentColorProvider.notifier,
                                )
                                .setColor(newColor);
                            ref
                                .read(LayerFormProvider.layerForm.notifier)
                                .setPickColor(false, ref);
                          }
                          return;
                        }

                        final timeLockInSeconds = ref
                            .read(LayerFormProvider.layerForm)
                            .timeLockInSeconds;
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

                        final color = ref
                            .read(CurrentColorProviders.currentColorProvider);

                        final result = await layerNotifier.addPendingPixels(
                          (event.localPosition.dx / 10).floor(),
                          (event.localPosition.dy / 10).floor(),
                          color,
                          ref,
                        );

                        if (result == false) {
                          final layerError =
                              ref.read(LayerFormProvider.layerForm);
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
                          size: canvasSize,
                          painter: MyPainter(
                            ref: ref,
                            cursorPosition: _cursorPosition,
                          ),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ),
        ),
        if (_showLoupe && _loupePosition != null)
          LoupeOverlay(
            position: _loupePosition!,
            painter: MyPainter(
              ref: ref,
              cursorPosition: _loupePosition,
            ),
            loupeSize: 90,
            zoomLevel: zoomLevel,
          ),
        if (_cursorPosition != null)
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              color: Colors.orange[900],
              padding: const EdgeInsets.all(4),
              child: Text(
                'Position: (${(_cursorPosition!.dx / 10).floor()}, ${(_cursorPosition!.dy / 10).floor()})',
                style: const TextStyle(fontSize: 10, color: Colors.white),
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
