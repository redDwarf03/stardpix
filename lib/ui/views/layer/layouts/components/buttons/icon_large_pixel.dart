import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixelarticons/pixel.dart' as pixelarticons;
import 'package:stardpix/ui/views/layer/bloc/provider.dart';

class IconLargePixel extends ConsumerWidget {
  const IconLargePixel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zoomLevel = ref.watch(LayerFormProvider.layerForm).zoomLevel;
    return IconButton(
      tooltip: zoomLevel == 0
          ? 'Enable Large Pixels (accessibility)'
          : zoomLevel == 1
              ? 'Enable Extra Large Pixels (accessibility)'
              : 'Disable Large Pixels',
      onPressed: () {
        ref
            .read(LayerFormProvider.layerForm.notifier)
            .setZoomLevel((zoomLevel + 1) % 3);
      },
      icon: Container(
        height: 42,
        width: 50,
        decoration: BoxDecoration(
          color: zoomLevel != 0 ? Colors.deepPurple[100] : Colors.grey[300],
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              pixelarticons.Pixel.zoomin,
              size: 24,
              color: zoomLevel != 0 ? Colors.deepPurple[900] : Colors.black,
            ),
            Text(
              zoomLevel == 0
                  ? 'Zoom'
                  : zoomLevel == 1
                      ? 'Large'
                      : 'X-Large',
              style: TextStyle(
                fontSize: 8,
                color: zoomLevel != 0 ? Colors.deepPurple[900] : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
