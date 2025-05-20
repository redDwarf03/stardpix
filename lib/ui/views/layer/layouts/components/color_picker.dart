import 'package:flutter/material.dart';
import 'package:flutter_hsvcolor_picker/flutter_hsvcolor_picker.dart'
    as color_picker;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixelarticons/pixel.dart' as pixelarticons;
import 'package:stardpix/ui/views/layer/bloc/provider.dart';

class ColorPicker extends ConsumerWidget {
  const ColorPicker({
    super.key,
    required this.color,
    required this.onColorChanged,
  });

  final Color color;
  final void Function(Color) onColorChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 55),
        decoration: BoxDecoration(
          border: Border.all(width: 3),
          gradient: const LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.red,
              Colors.orangeAccent,
            ],
          ),
        ),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            color_picker.ColorPicker(
              color: color,
              onChanged: onColorChanged,
              initialPicker: color_picker.Picker.swatches,
            ),
            SizedBox(
              width: 50,
              height: 53,
              child: IconButton(
                tooltip: 'Close',
                onPressed: () {
                  ref
                      .read(LayerFormProvider.layerForm.notifier)
                      .setDisplayColorPicker(false);
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[200],
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
                  child: Icon(
                    pixelarticons.Pixel.close,
                    size: 16,
                    color: Colors.orange[900],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}
