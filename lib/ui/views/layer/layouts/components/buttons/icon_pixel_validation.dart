import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixelarticons/pixel.dart' as pixelarticons;
import 'package:stardpix/application/balance.dart';
import 'package:stardpix/application/pixels.dart';
import 'package:stardpix/application/pixels_canvas.dart';
import 'package:stardpix/application/services/war_service.dart';
import 'package:stardpix/application/session/provider.dart';
import 'package:stardpix/ui/views/layer/bloc/provider.dart';
import 'package:starknet_provider/starknet_provider.dart';

class IconPixelValidation extends ConsumerWidget {
  const IconPixelValidation({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layer = ref.watch(LayerFormProvider.layerForm);
    return Row(
      children: [
        IconButton(
          tooltip: 'Validate',
          onPressed: () async {
            if (layer.pendingPixels.isEmpty ||
                ref.read(LayerFormProvider.layerForm).createInProgress ==
                    true) {
              return;
            }

            ref
                .read(LayerFormProvider.layerForm.notifier)
                .setCreateInProgress(true);

            final accountAsync =
                await ref.read(accountStarknetProvider(context).future);
            if (accountAsync == null) {
              return;
            }

            // Get the .env infos for the contract addresses
            const contractAddressStr =
                String.fromEnvironment('PIXELWAR_CONTRACT_ADDRESS');
            const pixTokenAddressStr =
                String.fromEnvironment('PIX_TOKEN_CONTRACT_ADDRESS');
            const rpcUrlStr = String.fromEnvironment('RPC_URL');

            // Fallback if String.fromEnvironment doesn't work (dev)
            final env = dotenv.env;
            final contractAddress = contractAddressStr.isNotEmpty
                ? contractAddressStr
                : env['PIXELWAR_CONTRACT_ADDRESS'] ?? '';
            final pixTokenAddress = pixTokenAddressStr.isNotEmpty
                ? pixTokenAddressStr
                : env['PIX_TOKEN_CONTRACT_ADDRESS'] ?? '';
            final rpcUrl =
                rpcUrlStr.isNotEmpty ? rpcUrlStr : env['RPC_URL'] ?? '';

            if (contractAddress.isEmpty ||
                pixTokenAddress.isEmpty ||
                rpcUrl.isEmpty) {
              return;
            }

            final result = await PixelWarService.fromAccount(
              provider: JsonRpcProvider(nodeUri: Uri.parse(rpcUrl)),
              contractAddressStr: contractAddress,
              account: accountAsync,
              pixTokenAddress: pixTokenAddress,
            ).addPixels(
              layer.pendingPixels,
            );

            result.map(
              success: (result) async {
                final pixels = await ref.read(fetchPixelsProvider.future);
                ref
                    .read(PixelCanvasProviders.pixelCanvasProvider.notifier)
                    .updatePixelsList([...pixels], ref);
                ref
                    .read(LayerFormProvider.layerForm.notifier)
                    .clearPendingPixels();
                ref.invalidate(userBalanceBigIntProvider);

                await ref
                    .read(LayerFormProvider.layerForm.notifier)
                    .getTimeLockInSeconds(context);

                ref
                  ..invalidate(userBalanceProvider)
                  ..invalidate(userBalanceBigIntProvider)
                  ..invalidate(userStrkBalanceBigIntProvider);
              },
              failure: (failure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  _displaySnackbar(
                    context,
                    failure.failure.message,
                  ),
                );
              },
            );

            ref
                .read(LayerFormProvider.layerForm.notifier)
                .setCreateInProgress(false);
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
            child: layer.createInProgress
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: LinearProgressIndicator(
                      color: Colors.green[900],
                      backgroundColor: Colors.green[100],
                    ),
                  )
                : Column(
                    children: [
                      Icon(
                        pixelarticons.Pixel.plus,
                        size: 24,
                        color: Colors.green[900],
                      ),
                      Text(
                        'Valid.',
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.green[900],
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

SnackBar _displaySnackbar(BuildContext context, String text) {
  return SnackBar(
    backgroundColor: Colors.orangeAccent,
    content: Text(
      text,
      style: const TextStyle(
        color: Colors.black87,
      ),
    ),
    duration: const Duration(seconds: 2),
  );
}
