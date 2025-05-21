import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixelarticons/pixel.dart' as pixelarticons;
import 'package:stardpix/application/balance.dart';
import 'package:stardpix/application/constants.dart';
import 'package:stardpix/application/session/provider.dart';
import 'package:stardpix/ui/views/layer/bloc/provider.dart';

class IconBuy extends ConsumerWidget {
  const IconBuy({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userPixBalanceAsyncValue = ref.watch(userBalanceBigIntProvider);
    final session = ref.watch(sessionNotifierProvider);
    final layer = ref.watch(LayerFormProvider.layerForm);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: session.isConnected
              ? 'Get PIX tokens to play'
              : 'Connect wallet to buy PIX Tokens',
          onPressed: session.isConnected == false
              ? null
              : () {
                  ref
                      .read(LayerFormProvider.layerForm.notifier)
                      .setIsBuyProcess(true, ref);
                },
          icon: Container(
            height: 42,
            width: 50,
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
            child: Column(
              children: [
                Icon(
                  pixelarticons.Pixel.briefcaseplus,
                  size: 24,
                  color: session.isConnected
                      ? Colors.orange[900]
                      : Colors.orange[900]!.withOpacity(0.2),
                ),
                Text(
                  'Buy',
                  style: TextStyle(
                    fontSize: 8,
                    color: session.isConnected
                        ? Colors.orange[900]
                        : Colors.orange[900]!.withOpacity(0.2),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          right: -1,
          top: -5,
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.green[100],
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
              child: userPixBalanceAsyncValue.when(
                data: (balanceBigInt) {
                  {
                    final balanceInPixUnits = balanceBigInt ~/ bigIntTenPow18;
                    final remainingPix =
                        balanceInPixUnits.toInt() - layer.nbPixEdit;
                    return Text(
                      '$remainingPix',
                      style: TextStyle(
                        color: remainingPix >= 0
                            ? Colors.green[900]
                            : Colors.red[900],
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }
                },
                loading: () => const SizedBox(),
                error: (error, stack) => const SizedBox(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
