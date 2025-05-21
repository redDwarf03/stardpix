import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixelarticons/pixel.dart' as pixelarticons;
import 'package:stardpix/ui/views/layer/bloc/provider.dart';

class IconPick extends ConsumerWidget {
  const IconPick({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pickColor = ref.watch(LayerFormProvider.layerForm).pickColor;
    return IconButton(
      tooltip: 'Pick color',
      onPressed: () {
        ref
            .read(LayerFormProvider.layerForm.notifier)
            .setPickColor(!pickColor, ref);
      },
      icon: Container(
        height: 42,
        width: 50,
        decoration: BoxDecoration(
          color: pickColor ? Colors.green[100] : Colors.orange[200],
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
          children: [
            Icon(
              pixelarticons.Pixel.loader,
              size: 24,
              color: pickColor ? Colors.green[900] : Colors.orange[900],
            ),
            Text(
              'Pick',
              style: TextStyle(
                fontSize: 8,
                color: pickColor ? Colors.green[900] : Colors.orange[900],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
