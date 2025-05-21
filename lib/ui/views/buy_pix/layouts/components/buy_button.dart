import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stardpix/ui/views/buy_pix/bloc/provider.dart';
import 'package:stardpix/ui/views/layer/bloc/provider.dart';

class BuyButton extends ConsumerWidget {
  const BuyButton({super.key, this.selectedPixAmount});
  final int? selectedPixAmount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buyTokenForm = ref.watch(BuyTokenFormProvider.buyTokenForm);
    final buyTokenFormNotifier =
        ref.read(BuyTokenFormProvider.buyTokenForm.notifier);

    final isDisabled = selectedPixAmount == null ||
        selectedPixAmount! <= 0 ||
        buyTokenForm.isLoadingFee;

    if (buyTokenForm.walletValidationInProgress) {
      return TextButton(
        onPressed: null,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange[200],
            boxShadow: [
              BoxShadow(
                color: Colors.orange[900]!.withValues(alpha: 0.2),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(width: 3),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Please wait...',
                style: TextStyle(
                  color: Colors.orange[900],
                ),
              ),
              const SizedBox(width: 10),
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
      );
    }

    return TextButton(
      onPressed: isDisabled
          ? null
          : () async {
              final result = await buyTokenFormNotifier.buy(context, ref);
              if (result) {
                ref
                    .read(LayerFormProvider.layerForm.notifier)
                    .setIsBuyProcess(false, ref);
              }
            },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDisabled
              ? Colors.orange[200]!.withValues(alpha: 0.2)
              : Colors.orange[200],
          boxShadow: [
            BoxShadow(
              color: Colors.orange[200]!.withValues(alpha: 0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(width: 3),
        ),
        child: Text(
          AppLocalizations.of(context)!.btn_buy_token,
          style: const TextStyle(
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
