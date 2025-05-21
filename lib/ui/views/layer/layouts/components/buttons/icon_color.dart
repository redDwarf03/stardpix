import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixelarticons/pixel.dart' as pixelarticons;
import 'package:stardpix/application/current_color.dart';
import 'package:stardpix/ui/views/layer/bloc/provider.dart';

class IconColor extends ConsumerWidget {
  const IconColor({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'Choose color',
      onPressed: () {
        ref
            .read(LayerFormProvider.layerForm.notifier)
            .setDisplayColorPicker(true);
      },
      icon: Container(
        height: 42,
        width: 50,
        decoration: BoxDecoration(
          color: ref.watch(
            CurrentColorProviders.currentColorProvider,
          ),
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
              pixelarticons.Pixel.drop,
              size: 24,
              color: Colors.orange[900],
            ),
            Text(
              'Color',
              style: TextStyle(
                fontSize: 8,
                color: Colors.orange[900],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
