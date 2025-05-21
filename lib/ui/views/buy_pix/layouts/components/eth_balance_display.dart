import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stardpix/application/balance.dart';
import 'package:stardpix/ui/views/buy_pix/layouts/components/token_balance_display.dart';

class EthBalanceDisplay extends ConsumerWidget {
  const EthBalanceDisplay({super.key, required this.textTheme});
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userEthBalanceAsyncValue = ref.watch(userEthBalanceBigIntProvider);

    return TokenBalanceDisplay(
      balanceAsyncValue: userEthBalanceAsyncValue,
      tokenSymbol: 'ETH',
      decimalsToShow: 6,
      loadingText: 'Loading ETH balance...',
      errorText: 'Could not load ETH balance',
    );
  }
}
