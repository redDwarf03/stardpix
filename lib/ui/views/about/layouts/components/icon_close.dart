import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixelarticons/pixel.dart' as pixelarticons;
import 'package:stardpix/ui/views/layer/bloc/provider.dart';

class IconClose extends ConsumerWidget {
  const IconClose({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Close',
          onPressed: () {
            ref
                .read(LayerFormProvider.layerForm.notifier)
                .setDisplayAbout(false, ref);
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange[200],
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
            child: Icon(
              pixelarticons.Pixel.close,
              size: 16,
              color: Colors.orange[900],
            ),
          ),
        ),
      ],
    );
  }
}
