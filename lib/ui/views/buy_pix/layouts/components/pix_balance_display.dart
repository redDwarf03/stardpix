import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stardpix/application/balance.dart';
import 'package:stardpix/ui/views/buy_pix/layouts/components/token_balance_display.dart';

class PixBalanceDisplay extends ConsumerWidget {
  const PixBalanceDisplay({super.key, required this.textTheme});
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userPixBalanceAsyncValue = ref.watch(userBalanceBigIntProvider);

    return TokenBalanceDisplay(
      balanceAsyncValue: userPixBalanceAsyncValue,
      tokenSymbol: 'PIX',
      decimalsToShow: 0,
      loadingText: 'Loading PIX balance...',
      errorText: 'Error fetching PIX balance',
      customFormattedText: (amount, symbol) {
        final balanceInPixUnits = BigInt.tryParse(amount) ?? BigInt.zero;
        if (balanceInPixUnits > BigInt.zero) {
          return 'You already have $amount $symbol';
        } else {
          return "You don't have $symbol yet. It's time to change that!";
        }
      },
    );
  }
}
