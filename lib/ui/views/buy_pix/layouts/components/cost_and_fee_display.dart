import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stardpix/application/constants.dart';
import 'package:stardpix/ui/views/buy_pix/bloc/provider.dart';

class CostAndFeeDisplay extends ConsumerWidget {
  const CostAndFeeDisplay({
    super.key,
    required this.textTheme,
    this.selectedPixAmount,
  });
  final TextTheme textTheme;
  final int? selectedPixAmount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buyTokenForm = ref.watch(BuyTokenFormProvider.buyTokenForm);

    if (selectedPixAmount == null ||
        selectedPixAmount! <= 0 ||
        buyTokenForm.correspondingFriAmount == null) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            'Cost: ${(buyTokenForm.correspondingFriAmount! / bigIntTenPow18).toStringAsFixed(0)} FRI for $selectedPixAmount PIX',
            style: textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
        ),
        if (buyTokenForm.isLoadingFee)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Estimating fee... ',
                  style: TextStyle(color: Colors.amber),
                ),
                SizedBox(width: 10),
                SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
          )
        else if (buyTokenForm.estimatedFee != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'Network Fee: ${(buyTokenForm.estimatedFee!.maxFee.toBigInt() / bigIntTenPow18).toStringAsFixed(6)} ${buyTokenForm.estimatedFee!.unit.toLowerCase() == 'wei' ? 'ETH' : buyTokenForm.estimatedFee!.unit.toUpperCase()}',
              style: textTheme.bodySmall?.copyWith(color: Colors.amber[200]),
            ),
          ),
      ],
    );
  }
}
