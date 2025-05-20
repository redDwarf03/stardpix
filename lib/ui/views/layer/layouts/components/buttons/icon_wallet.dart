import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixelarticons/pixel.dart' as pixelarticons;
import 'package:stardpix/application/balance.dart';
import 'package:stardpix/application/pixels.dart';
import 'package:stardpix/application/pixels_canvas.dart';
import 'package:stardpix/application/session/provider.dart';

class IconWallet extends ConsumerWidget {
  const IconWallet({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionNotifierProvider);
    return Row(
      children: [
        IconButton(
          tooltip: session.isConnected
              ? 'Disconnect wallet'
              : 'Connect wallet to play',
          onPressed: () async {
            final sessionNotifier = ref.read(sessionNotifierProvider.notifier);
            if (session.isConnected) {
              // await sessionNotifier.cancelConnection();
              ref.invalidate(userBalanceProvider);

              final pixels = await ref.read(fetchPixelsProvider.future);
              ref
                  .read(PixelCanvasProviders.pixelCanvasProvider.notifier)
                  .updatePixelsList(pixels, ref);
              return;
            }

            await sessionNotifier.connectWallet();

            final pixels = await ref.read(fetchPixelsProvider.future);

            ref
                .read(
                  PixelCanvasProviders.pixelCanvasProvider.notifier,
                )
                .updatePixelsList(pixels, ref);
            ref.invalidate(userBalanceProvider);

            if (ref.read(sessionNotifierProvider).error.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor:
                      Theme.of(context).snackBarTheme.backgroundColor,
                  content: Text(
                    ref.read(sessionNotifierProvider).error,
                    style: Theme.of(context).snackBarTheme.contentTextStyle,
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          icon: Container(
            height: 42,
            width: 50,
            decoration: BoxDecoration(
              color:
                  session.isConnected ? Colors.green[100] : Colors.orange[200],
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
                  pixelarticons.Pixel.wallet,
                  size: 24,
                  color: session.isConnected
                      ? Colors.green[900]
                      : Colors.orange[900],
                ),
                Text(
                  'Wallet',
                  style: TextStyle(
                    fontSize: 8,
                    color: session.isConnected
                        ? Colors.green[900]
                        : Colors.orange[900],
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
