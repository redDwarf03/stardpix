import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stardpix/application/balance.dart';
import 'package:stardpix/application/constants.dart';
import 'package:stardpix/ui/views/buy_pix/layouts/components/token_balance_display.dart';

class StrkBalanceDisplay extends ConsumerWidget {
  const StrkBalanceDisplay({
    super.key,
    required this.textTheme,
    required this.selectedPixAmount,
    required this.onPixAmountChanged,
  });
  final TextTheme textTheme;
  final int? selectedPixAmount;
  final ValueChanged<int?> onPixAmountChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userStrkBalanceAsyncValue = ref.watch(userStrkBalanceBigIntProvider);
    const pixPurchaseOptions = [1, 2, 5, 10, 20, 40, 50, 75, 100];

    return userStrkBalanceAsyncValue.when(
      data: (strkBalanceBigInt) {
        final strkBalanceDouble =
            strkBalanceBigInt.toDouble() / bigIntTenPow18.toDouble();
        final maxPixBuyable = (strkBalanceDouble / strkPerPixRate).floor();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TokenBalanceDisplay(
              balanceAsyncValue: userStrkBalanceAsyncValue,
              tokenSymbol: 'STRK',
              loadingText: 'Loading STRK balance...',
              errorText: 'Error fetching STRK balance',
            ),
            const SizedBox(height: 35),
            if (maxPixBuyable <= 0) ...[
              Text(
                'You do not have enough STRK to buy PIX.',
                style:
                    textTheme.bodyMedium?.copyWith(color: Colors.yellowAccent),
              ),
            ] else ...[
              Text(
                'Select amount of PIX to buy:',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.1),
                ),
                child: DropdownButton<int>(
                  value: selectedPixAmount,
                  hint: Text(
                    'Select PIX amount',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  isExpanded: true,
                  underline: const SizedBox(),
                  dropdownColor: const Color(0xFF5d4cb8),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                  items: pixPurchaseOptions
                      .where((amount) => amount <= maxPixBuyable)
                      .map<DropdownMenuItem<int>>((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text('$value PIX'),
                    );
                  }).toList(),
                  onChanged: onPixAmountChanged,
                ),
              ),
            ],
          ],
        );
      },
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TokenBalanceDisplay(
            balanceAsyncValue: userStrkBalanceAsyncValue,
            tokenSymbol: 'STRK',
            loadingText: 'Loading STRK balance...',
            errorText: 'Error fetching STRK balance',
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Text(
                'Checking available PIX amounts...',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: 10),
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
        ],
      ),
      error: (err, stack) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TokenBalanceDisplay(
            balanceAsyncValue: userStrkBalanceAsyncValue,
            tokenSymbol: 'STRK',
            loadingText: 'Loading STRK balance...',
            errorText: 'Error fetching STRK balance',
          ),
          const SizedBox(height: 15),
          Text(
            'Could not determine PIX purchase options.',
            style: textTheme.bodyMedium?.copyWith(color: Colors.yellowAccent),
          ),
        ],
      ),
    );
  }
}
