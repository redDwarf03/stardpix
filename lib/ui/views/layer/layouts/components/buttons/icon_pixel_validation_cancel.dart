import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixelarticons/pixel.dart' as pixelarticons;
import 'package:stardpix/application/balance.dart';
import 'package:stardpix/ui/views/layer/bloc/provider.dart';

class IconPixelValicationCancel extends ConsumerWidget {
  const IconPixelValicationCancel({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Cancel All',
          onPressed: () async {
            if (ref.read(LayerFormProvider.layerForm).createInProgress ==
                true) {
              return;
            }

            await ref
                .read(LayerFormProvider.layerForm.notifier)
                .cancelValidation(ref);

            ref
              ..invalidate(userBalanceProvider)
              ..invalidate(userBalanceBigIntProvider)
              ..invalidate(userStrkBalanceBigIntProvider);
          },
          icon: Container(
            height: 42,
            width: 50,
            decoration: BoxDecoration(
              color: Colors.red[100],
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
                  pixelarticons.Pixel.undo,
                  size: 24,
                  color: Colors.red[900],
                ),
                Text(
                  'Undo',
                  style: TextStyle(
                    fontSize: 8,
                    color: Colors.red[900],
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
