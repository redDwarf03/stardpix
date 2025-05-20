import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stardpix/application/balance.dart';
import 'package:stardpix/ui/views/buy_pix/bloc/provider.dart';
import 'package:stardpix/ui/views/buy_pix/layouts/components/icon_close.dart';
import 'package:stardpix/ui/views/layer/bloc/provider.dart';

final BigInt bigIntTenPow18 = BigInt.parse('1000000000000000000');
const int friPerPixRate = 100;

class BuyScreen extends ConsumerStatefulWidget {
  const BuyScreen({
    super.key,
  });

  @override
  ConsumerState<BuyScreen> createState() => BuyScreenState();
}

class BuyScreenState extends ConsumerState<BuyScreen> {
  int? _selectedPixAmount; // Pour stocker la sélection locale du Dropdown

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
    final userPixBalanceAsyncValue = ref.watch(userBalanceBigIntProvider);
    final userFriBalanceAsyncValue = ref.watch(userFriBalanceBigIntProvider);
    final userEthBalanceAsyncValue = ref.watch(userEthBalanceBigIntProvider);
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
                  left: 30,
                  right: 30,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text('Buy PIX token', style: textTheme.titleMedium),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rate: $friPerPixRate FRI = 1 PIX',
                          style: textTheme.bodySmall,
                        ),
                        Text(
                          'Cost: 1 PIX = 1 Pixel (plus transaction fees)',
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    userPixBalanceAsyncValue.when(
                      data: (balanceBigInt) {
                        final balanceInPixUnits =
                            balanceBigInt ~/ bigIntTenPow18;
                        if (balanceInPixUnits > BigInt.zero) {
                          return Text(
                            'You already have $balanceInPixUnits PIX',
                            style: textTheme.bodyMedium,
                          );
                        } else {
                          return const Text(
                            "You don't have PIX yet. It's time to change that!",
                            style: TextStyle(fontSize: 16),
                          );
                        }
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (error, stack) {
                        return Text(
                          'Error fetching PIX balance: $error',
                          style: TextStyle(color: Colors.red[300]),
                        );
                      },
                    ),
                    const SizedBox(height: 5),
                    userEthBalanceAsyncValue.when(
                      data: (ethBalanceBigInt) {
                        final ethBalanceForDisplay =
                            ethBalanceBigInt.toDouble() /
                                bigIntTenPow18.toDouble();
                        return Text(
                          'Your ETH Balance: ${ethBalanceForDisplay.toStringAsFixed(6)} ETH',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.normal,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        );
                      },
                      loading: () => const Text(
                        'Loading ETH balance...',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                        ),
                      ),
                      error: (error, stack) => Text(
                        'Could not load ETH balance',
                        style: TextStyle(
                          color: Colors.orange[300],
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    userFriBalanceAsyncValue.when(
                      data: (friBalanceBigInt) {
                        final friBalanceForDisplay =
                            friBalanceBigInt.toDouble() /
                                bigIntTenPow18.toDouble();
                        return Text(
                          'Your FRI Balance: ${friBalanceForDisplay.toStringAsFixed(2)} FRI',
                          style: textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        );
                      },
                      loading: () => const Text(
                        'Loading FRI balance...',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                      error: (error, stack) => Text(
                        'Could not load FRI balance',
                        style: TextStyle(color: Colors.orange[300]),
                      ),
                    ),
                    const SizedBox(height: 15),
                    userFriBalanceAsyncValue.when(
                      data: (friBalanceBigInt) {
                        final friBalanceDoubleForUI =
                            friBalanceBigInt.toDouble() /
                                bigIntTenPow18.toDouble();
                        final maxPixBuyable =
                            (friBalanceDoubleForUI / friPerPixRate).floor();

                        if (maxPixBuyable <= 0) {
                          return Text(
                            'You do not have enough FRI to buy PIX. Current FRI Balance: ${friBalanceDoubleForUI.toStringAsFixed(2)}',
                            style: textTheme.bodyMedium
                                ?.copyWith(color: Colors.yellowAccent),
                          );
                        }

                        final dropdownItems =
                            List<DropdownMenuItem<int>>.generate(
                          maxPixBuyable,
                          (index) => DropdownMenuItem(
                            value: index + 1,
                            child: Text('${index + 1} PIX'),
                          ),
                        );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                color: Colors.black.withOpacity(0.1),
                              ),
                              child: DropdownButton<int>(
                                value: _selectedPixAmount,
                                hint: const Text(
                                  'Select PIX amount',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                isExpanded: true,
                                underline: const SizedBox(),
                                dropdownColor: const Color(0xFF5d4cb8),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                                items: dropdownItems,
                                onChanged: (int? newValue) {
                                  setState(() {
                                    _selectedPixAmount = newValue;
                                  });
                                  if (newValue != null) {
                                    buyTokenFormNotifier
                                        .selectPixAmountAndEstimateFee(
                                      newValue,
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => const Column(
                        children: [
                          Text('Loading FRI Balance...'),
                          CircularProgressIndicator(),
                        ],
                      ),
                      error: (err, stack) => Text(
                        'Error fetching FRI balance: $err',
                        style: TextStyle(color: Colors.red[300]),
                      ),
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
                    if (_selectedPixAmount != null &&
                        _selectedPixAmount! > 0 &&
                        buyTokenForm.correspondingFriAmount != null)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 4),
                            child: Text(
                              'Cost: ${(buyTokenForm.correspondingFriAmount! / bigIntTenPow18).toStringAsFixed(0)} FRI for $_selectedPixAmount PIX',
                              style: textTheme.bodyMedium
                                  ?.copyWith(color: Colors.white70),
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
                                style: textTheme.bodySmall
                                    ?.copyWith(color: Colors.amber[200]),
                              ),
                            ),
                        ],
                      ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!buyTokenForm.walletValidationInProgress)
                            TextButton(
                              onPressed: (_selectedPixAmount == null ||
                                      _selectedPixAmount! <= 0 ||
                                      buyTokenForm.isLoadingFee)
                                  ? null
                                  : () async {
                                      final result = await buyTokenFormNotifier
                                          .buy(context, ref);
                                      if (result) {
                                        ref
                                            .read(
                                              LayerFormProvider
                                                  .layerForm.notifier,
                                            )
                                            .setIsBuyProcess(false, ref);
                                        setState(() {
                                          _selectedPixAmount = null;
                                        });
                                      }
                                    },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: (_selectedPixAmount == null ||
                                          _selectedPixAmount! <= 0 ||
                                          buyTokenForm.isLoadingFee)
                                      ? Colors.grey[600]
                                      : Colors.orange[200],
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
                                child: Text(
                                  AppLocalizations.of(context)!.btn_buy_token,
                                  style: TextStyle(
                                    color: Colors.orange[900],
                                  ),
                                ),
                              ),
                            )
                          else
                            TextButton(
                              onPressed: null,
                              child: Container(
                                padding: const EdgeInsets.all(8),
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
                                child: Row(
                                  children: [
                                    Text(
                                      'Confirm in your wallet',
                                      style: TextStyle(
                                        color: Colors.orange[900],
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    SizedBox(
                                      width: 10,
                                      height: 10,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1,
                                        color: Colors.orange[900],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
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
