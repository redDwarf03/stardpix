import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stardpix/application/constants.dart';

class TokenBalanceDisplay extends ConsumerWidget {
  const TokenBalanceDisplay({
    super.key,
    required this.balanceAsyncValue,
    required this.tokenSymbol,
    this.loadingText = 'Loading balance...',
    this.errorText = 'Could not load balance',
    this.decimalsToShow = 2,
  });
  final AsyncValue<BigInt> balanceAsyncValue;
  final String tokenSymbol;
  final String loadingText;
  final String errorText;
  final int decimalsToShow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return balanceAsyncValue.when(
      data: (balanceBigInt) {
        final balanceDouble =
            balanceBigInt.toDouble() / bigIntTenPow18.toDouble();
        final formattedAmount = balanceDouble.toStringAsFixed(decimalsToShow);

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your $tokenSymbol Balance: ',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Row(
              children: [
                Text(
                  formattedAmount,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  ' $tokenSymbol',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        );
      },
      loading: () => Row(
        children: [
          Text(
            loadingText,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(width: 4),
          const SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 1,
            ),
          ),
        ],
      ),
      error: (error, stack) {
        var errorMsg = error.toString();
        if (errorMsg.length > 50) {
          errorMsg = '${errorMsg.substring(0, 47)}...';
        }
        return Text(
          '$errorText: $errorMsg',
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: Colors.red[400],
                fontSize:
                    Theme.of(context).textTheme.bodySmall!.fontSize != null
                        ? Theme.of(context).textTheme.bodySmall!.fontSize! * 0.9
                        : 12,
              ),
        );
      },
    );
  }
}
