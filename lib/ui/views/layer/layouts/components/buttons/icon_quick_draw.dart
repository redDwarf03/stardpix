import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixelarticons/pixel.dart' as pixelarticons;
import 'package:stardpix/ui/views/layer/bloc/provider.dart';

class IconQuickDraw extends ConsumerWidget {
  const IconQuickDraw({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quickDrawMode = ref.watch(LayerFormProvider.layerForm).quickDrawMode;
    return IconButton(
      tooltip:
          quickDrawMode ? 'Disable Quick Draw Mode' : 'Enable Quick Draw Mode',
      onPressed: () {
        ref
            .read(LayerFormProvider.layerForm.notifier)
            .setQuickDrawMode(!quickDrawMode);
      },
      icon: Container(
        height: 42,
        width: 50,
        decoration: BoxDecoration(
          color: quickDrawMode ? Colors.blue[100] : Colors.grey[300],
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
              pixelarticons.Pixel.timeline,
              size: 24,
              color: quickDrawMode ? Colors.blue[900] : Colors.black,
            ),
            Text(
              'Quick',
              style: TextStyle(
                fontSize: 8,
                color: quickDrawMode ? Colors.blue[900] : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
