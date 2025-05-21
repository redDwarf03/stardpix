import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixelarticons/pixel.dart' as pixelarticons;
import 'package:stardpix/application/session/provider.dart';
import 'package:stardpix/ui/views/layer/bloc/provider.dart';

class IconWallet extends ConsumerWidget {
  const IconWallet({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConnected = ref.watch(isConnectedProvider);
    return Row(
      children: [
        IconButton(
          onPressed: () {
            ref
                .read(LayerFormProvider.layerForm.notifier)
                .setIsWalletProcess(true, ref);
          },
          icon: Container(
            height: 42,
            width: 50,
            decoration: BoxDecoration(
              color: isConnected ? Colors.green[100] : Colors.orange[200],
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
                  pixelarticons.Pixel.wallet,
                  size: 24,
                  color: isConnected ? Colors.green[900] : Colors.orange[900],
                ),
                Text(
                  'Wallet',
                  style: TextStyle(
                    fontSize: 8,
                    color: isConnected ? Colors.green[900] : Colors.orange[900],
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
