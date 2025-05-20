import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixelarticons/pixel.dart' as pixelarticons;
import 'package:stardpix/ui/views/layer/bloc/provider.dart';
import 'package:stardpix/ui/views/layer/bloc/state.dart';

class IconEdit extends ConsumerWidget {
  const IconEdit({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layer = ref.watch(LayerFormProvider.layerForm);

    if (layer.timeLockInSeconds > 0 || layer.createInProgress) {
      return const SizedBox.shrink();
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: layer.mode == Mode.edit ? 'Edit' : 'Erase',
          onPressed: () {
            ref.read(LayerFormProvider.layerForm.notifier).setMode(
                  layer.mode == Mode.edit ? Mode.erase : Mode.edit,
                );
          },
          icon: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                height: 42,
                width: 50,
                decoration: BoxDecoration(
                  color: layer.mode == Mode.edit
                      ? Colors.green[100]
                      : Colors.orange[200],
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
                child: Column(
                  children: [
                    Icon(
                      layer.mode == Mode.edit
                          ? pixelarticons.Pixel.edit
                          : pixelarticons.Pixel.delete,
                      size: 24,
                      color: layer.mode == Mode.edit
                          ? Colors.green[900]
                          : Colors.orange[900],
                    ),
                    Text(
                      layer.mode == Mode.edit ? 'Edit' : 'Delete',
                      style: TextStyle(
                        fontSize: 8,
                        color: layer.mode == Mode.edit
                            ? Colors.green[900]
                            : Colors.orange[900],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: -1,
          top: -5,
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: layer.mode == Mode.edit
                  ? Colors.green[100]
                  : Colors.orange[200],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            constraints: const BoxConstraints(
              minWidth: 16,
              minHeight: 16,
            ),
            child: Center(
              child: Text(
                '${layer.nbPixEdit}/${layer.maxPixEdit}',
                style: TextStyle(
                  color: layer.mode == Mode.edit
                      ? Colors.green[900]
                      : Colors.orange[900],
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
