import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:stardpix/application/balance.dart';
import 'package:stardpix/application/constants.dart';
import 'package:stardpix/application/services/dpixou_service.dart';
import 'package:stardpix/ui/views/buy_pix/bloc/state.dart';

final _buyTokenFormProvider =
    NotifierProvider.autoDispose<BuyTokenFormNotifier, BuyTokenFormState>(
  () {
    return BuyTokenFormNotifier();
  },
);

class BuyTokenFormNotifier extends AutoDisposeNotifier<BuyTokenFormState> {
  BuyTokenFormNotifier();

  final Logger logger = Logger('BuyTokenFormNotifier');
  @override
  BuyTokenFormState build() {
    return const BuyTokenFormState();
  }

  Future<void> selectPixAmountAndEstimateFee(int pixAmount) async {
    if (pixAmount <= 0) {
      state = state.copyWith(
        selectedPixAmount: null,
        correspondingFriAmount: null,
        estimatedFee: null,
        error: 'Please select a valid amount of PIX',
        isLoadingFee: false,
      );
      return;
    }

    final friCostForPixBase = BigInt.from(pixAmount * 100);
    final friCostForPixWithDecimals = friCostForPixBase * bigIntTenPow18;

    state = state.copyWith(
      selectedPixAmount: pixAmount,
      correspondingFriAmount: friCostForPixWithDecimals,
      estimatedFee: null,
      error: null,
      isLoadingFee: true,
    );

    try {
      final fee = await DpixouService.defaultConfig()
          .estimateBuyPixFee(friCostForPixWithDecimals);
      if (state.selectedPixAmount == pixAmount) {
        state =
            state.copyWith(estimatedFee: fee, isLoadingFee: false, error: null);
      } else {
        state = state.copyWith(isLoadingFee: false);
      }
    } catch (e) {
      logger.severe('Error during fee estimation in notifier: $e');
      if (state.selectedPixAmount == pixAmount) {
        state = state.copyWith(
          estimatedFee: null,
          error: 'Failed to estimate fee',
          isLoadingFee: false,
        );
      }
    }
  }

  Future<bool> buy(BuildContext context, WidgetRef ref) async {
    if (state.selectedPixAmount == null ||
        state.selectedPixAmount! <= 0 ||
        state.correspondingFriAmount == null) {
      state = state.copyWith(
        error: 'Please select a valid amount of PIX to buy',
        walletValidationInProgress: false,
      );
      return false;
    }

    state = state.copyWith(walletValidationInProgress: true, error: null);

    final result = await DpixouService.defaultConfig().buyPix(
      state.correspondingFriAmount!,
    );

    return result.map(
      success: (success) async {
        ref
          ..invalidate(userBalanceBigIntProvider)
          ..invalidate(userFriBalanceBigIntProvider);
        state = state.copyWith(
          walletValidationInProgress: false,
          estimatedFee: null,
          selectedPixAmount: null,
          correspondingFriAmount: null,
          error: null,
        );
        return true;
      },
      failure: (error) {
        state = state.copyWith(
          walletValidationInProgress: false,
          error: error.failure.message,
        );
        return false;
      },
    );
  }
}

abstract class BuyTokenFormProvider {
  static final buyTokenForm = _buyTokenFormProvider;
}
