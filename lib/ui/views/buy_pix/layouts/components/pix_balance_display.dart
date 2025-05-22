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
      errorText: 'Could not load PIX balance',
    );
  }
}
