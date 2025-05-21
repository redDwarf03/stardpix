import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixelarticons/pixel.dart' as pixelarticons;
import 'package:stardpix/application/balance.dart';
import 'package:stardpix/application/pixels.dart';
import 'package:stardpix/application/pixels_canvas.dart';
import 'package:stardpix/ui/views/layer/bloc/provider.dart';

class IconRefresh extends ConsumerWidget {
  const IconRefresh({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layer = ref.watch(LayerFormProvider.layerForm);

    return Row(
      children: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: () async {
            if (layer.refreshInProgress) return;
            ref
                .read(LayerFormProvider.layerForm.notifier)
                .setRefreshInProgress(true);
            ref.invalidate(userBalanceProvider);
            final pixels = await ref.read(fetchPixelsProvider.future);
            final pendingPixels =
                ref.read(LayerFormProvider.layerForm).pendingPixels;
            ref
                .read(PixelCanvasProviders.pixelCanvasProvider.notifier)
                .updatePixelsList([...pixels, ...pendingPixels], ref);

            ref
                .read(LayerFormProvider.layerForm.notifier)
                .setRefreshInProgress(false);
          },
          icon: Container(
            height: 42,
            width: 50,
            decoration: BoxDecoration(
              color: layer.refreshInProgress
                  ? Colors.green[100]
                  : Colors.orange[200],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(width: 3),
            ),
            child: layer.refreshInProgress
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
                        pixelarticons.Pixel.reload,
                        size: 24,
                        color: Colors.orange[900],
                      ),
                      Text(
                        'Reload',
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.orange[900],
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
