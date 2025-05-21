import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stardpix/application/constants.dart';
import 'package:stardpix/ui/views/buy_pix/bloc/provider.dart';
import 'package:stardpix/ui/views/buy_pix/layouts/components/buy_button.dart';
import 'package:stardpix/ui/views/buy_pix/layouts/components/cost_and_fee_display.dart';
import 'package:stardpix/ui/views/buy_pix/layouts/components/eth_balance_display.dart';
import 'package:stardpix/ui/views/buy_pix/layouts/components/fri_balance_display.dart';
import 'package:stardpix/ui/views/buy_pix/layouts/components/icon_close.dart';
import 'package:stardpix/ui/views/buy_pix/layouts/components/pix_balance_display.dart';

class BuyScreen extends ConsumerStatefulWidget {
  const BuyScreen({
    super.key,
  });

  @override
  ConsumerState<BuyScreen> createState() => BuyScreenState();
}

class BuyScreenState extends ConsumerState<BuyScreen> {
  int? _selectedPixAmount;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buyTokenForm = ref.watch(BuyTokenFormProvider.buyTokenForm);
    final buyTokenFormNotifier =
        ref.read(BuyTokenFormProvider.buyTokenForm.notifier);

    final textTheme = Theme.of(context)
        .textTheme
        .apply(displayColor: Theme.of(context).colorScheme.onSurface);

    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            border: Border.all(width: 3),
          ),
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.orangeAccent, Colors.red],
              ),
            ),
            child: Container(
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                border: Border.all(width: 3),
              ),
              child: Container(
                width: 600,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                    colors: [Color(0xFF5d4cb8), Color(0xFF7276f9)],
                  ),
                ),
                padding: const EdgeInsets.only(
                  top: 10,
                  left: 10,
                  right: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text('Buy PIX token', style: textTheme.titleMedium),
                    const SizedBox(
                      height: 10,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rate: $friPerPixRate FRI = 1 PIX',
                          style: textTheme.bodySmall,
                        ),
                        Text(
                          'Cost: 1 PIX = 1 Pixel (+ transaction fees)',
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    PixBalanceDisplay(textTheme: textTheme),
                    const SizedBox(height: 15),
                    EthBalanceDisplay(textTheme: textTheme),
                    const SizedBox(height: 15),
                    FriBalanceDisplay(
                      textTheme: textTheme,
                      selectedPixAmount: _selectedPixAmount,
                      onPixAmountChanged: (newValue) {
                        setState(() {
                          _selectedPixAmount = newValue;
                        });
                        if (newValue != null) {
                          buyTokenFormNotifier
                              .selectPixAmountAndEstimateFee(newValue);
                        }
                      },
                    ),
                    if (buyTokenForm.error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          buyTokenForm.error!,
                          style: TextStyle(color: Colors.red[300]),
                        ),
                      )
                    else
                      const SizedBox(height: 24),
                    CostAndFeeDisplay(
                      textTheme: textTheme,
                      selectedPixAmount: _selectedPixAmount,
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          BuyButton(selectedPixAmount: _selectedPixAmount),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const Positioned(
          top: -1,
          right: -1,
          child: IconClose(),
        ),
      ],
    );
  }
}
