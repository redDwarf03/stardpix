import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixelarticons/pixel.dart' as pixelarticons;
import 'package:stardpix/ui/views/layer/bloc/provider.dart';

class IconAbout extends ConsumerWidget {
  const IconAbout({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'About',
      onPressed: () {
        ref
            .read(LayerFormProvider.layerForm.notifier)
            .setDisplayAbout(true, ref);
      },
      icon: Container(
        height: 42,
        width: 50,
        decoration: BoxDecoration(
          color: Colors.green[100],
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
              pixelarticons.Pixel.warningbox,
              size: 24,
              color: Colors.green[900],
            ),
            Text(
              'About',
              style: TextStyle(
                fontSize: 8,
                color: Colors.green[900],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
