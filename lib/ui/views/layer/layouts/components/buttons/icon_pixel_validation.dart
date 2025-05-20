import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixelarticons/pixel.dart' as pixelarticons;
import 'package:stardpix/application/balance.dart';
import 'package:stardpix/application/pixels.dart';
import 'package:stardpix/application/pixels_canvas.dart';
import 'package:stardpix/application/services/war_service.dart';
import 'package:stardpix/ui/views/layer/bloc/provider.dart';

class IconPixelValidation extends ConsumerWidget {
  const IconPixelValidation({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layer = ref.watch(LayerFormProvider.layerForm);
    return Row(
      children: [
        IconButton(
          tooltip: 'Validate',
          onPressed: () async {
            if (layer.pendingPixels.isEmpty ||
                ref.read(LayerFormProvider.layerForm).createInProgress ==
                    true) {
              return;
            }

            ref
                .read(LayerFormProvider.layerForm.notifier)
                .setCreateInProgress(true);

            final result = await PixelWarService.defaultConfig().addPixels(
              layer.pendingPixels,
            );

            result.map(
              success: (result) async {
                final pixels = await ref.read(fetchPixelsProvider.future);
                ref
                    .read(PixelCanvasProviders.pixelCanvasProvider.notifier)
                    .updatePixelsList([...pixels], ref);
                ref
                    .read(LayerFormProvider.layerForm.notifier)
                    .clearPendingPixels();
                ref.invalidate(userBalanceBigIntProvider);

                await ref
                    .read(LayerFormProvider.layerForm.notifier)
                    .getTimeLockInSeconds();
              },
              failure: (failure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  _displaySnackbar(
                    context,
                    failure.failure.message,
                  ),
                );
              },
            );

            ref
                .read(LayerFormProvider.layerForm.notifier)
                .setCreateInProgress(false);
          },
          icon: Container(
            height: 42,
            width: 50,
            decoration: BoxDecoration(
              color: Colors.green[100],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(width: 3),
            ),
            child: layer.createInProgress
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: LinearProgressIndicator(
                      color: Colors.green[900],
                      backgroundColor: Colors.green[100],
                    ),
                  )
                : Column(
                    children: [
                      Icon(
                        pixelarticons.Pixel.plus,
                        size: 24,
                        color: Colors.green[900],
                      ),
                      Text(
                        'Valid.',
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.green[900],
                        ),
                      ),
                    ],
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
