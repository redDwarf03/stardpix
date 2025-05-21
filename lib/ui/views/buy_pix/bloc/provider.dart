import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:stardpix/application/balance.dart';
import 'package:stardpix/application/constants.dart';
import 'package:stardpix/application/services/dpixou_service.dart';
import 'package:stardpix/application/session/provider.dart';
import 'package:stardpix/ui/views/buy_pix/bloc/state.dart';
import 'package:starknet_provider/starknet_provider.dart';

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

  Future<void> selectPixAmountAndEstimateFee(
    BuildContext context,
    int pixAmount,
  ) async {
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
      final selectedAccount =
          await ref.read(accountStarknetProvider(context).future);
      if (selectedAccount == null) {
        state = state.copyWith(
          estimatedFee: null,
          error: 'No account connected (wallet).',
          isLoadingFee: false,
        );
        return;
      }

      // Get the .env infos for the contract addresses
      const contractAddressStr =
          String.fromEnvironment('DPIXOU_CONTRACT_ADDRESS');
      const friTokenAddressStr =
          String.fromEnvironment('FRI_TOKEN_CONTRACT_ADDRESS');
      const rpcUrlStr = String.fromEnvironment('RPC_URL');

      // Fallback if String.fromEnvironment doesn't work (dev)
      final env = dotenv.env;
      final contractAddress = contractAddressStr.isNotEmpty
          ? contractAddressStr
          : env['DPIXOU_CONTRACT_ADDRESS'] ?? '';
      final friTokenAddress = friTokenAddressStr.isNotEmpty
          ? friTokenAddressStr
          : env['FRI_TOKEN_CONTRACT_ADDRESS'] ?? '';
      final rpcUrl = rpcUrlStr.isNotEmpty ? rpcUrlStr : env['RPC_URL'] ?? '';

      if (contractAddress.isEmpty ||
          friTokenAddress.isEmpty ||
          rpcUrl.isEmpty) {
        state = state.copyWith(
          estimatedFee: null,
          error: 'Missing configuration for the contracts or the RPC.',
          isLoadingFee: false,
        );
        return;
      }

      final fee = await DpixouService.fromAccount(
        provider: JsonRpcProvider(nodeUri: Uri.parse(rpcUrl)),
        contractAddressStr: contractAddress,
        account: selectedAccount,
        friTokenAddressStr: friTokenAddress,
      ).estimateBuyPixFee(friCostForPixWithDecimals);
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

    final accountAsync =
        await ref.read(accountStarknetProvider(context).future);
    if (accountAsync == null) {
      state = state.copyWith(
        walletValidationInProgress: false,
        error: 'No account connected (wallet).',
      );
      return false;
    }

    // Get the .env infos for the contract addresses
    const contractAddressStr =
        String.fromEnvironment('DPIXOU_CONTRACT_ADDRESS');
    const friTokenAddressStr =
        String.fromEnvironment('FRI_TOKEN_CONTRACT_ADDRESS');
    const rpcUrlStr = String.fromEnvironment('RPC_URL');

    // Fallback if String.fromEnvironment doesn't work (dev)
    final env = dotenv.env;
    final contractAddress = contractAddressStr.isNotEmpty
        ? contractAddressStr
        : env['DPIXOU_CONTRACT_ADDRESS'] ?? '';
    final friTokenAddress = friTokenAddressStr.isNotEmpty
        ? friTokenAddressStr
        : env['FRI_TOKEN_CONTRACT_ADDRESS'] ?? '';
    final rpcUrl = rpcUrlStr.isNotEmpty ? rpcUrlStr : env['RPC_URL'] ?? '';

    if (contractAddress.isEmpty || friTokenAddress.isEmpty || rpcUrl.isEmpty) {
      state = state.copyWith(
        walletValidationInProgress: false,
        error: 'Missing configuration for the contracts or the RPC.',
      );
      return false;
    }

    final dpixouService = DpixouService.fromAccount(
      provider: JsonRpcProvider(nodeUri: Uri.parse(rpcUrl)),
      contractAddressStr: contractAddress,
      account: accountAsync,
      friTokenAddressStr: friTokenAddress,
    );

    final result = await dpixouService.buyPix(
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
        logger
          ..severe(
            'Buy PIX failure: ${error.failure} | type: ${error.failure.runtimeType}',
          )
          ..severe('Buy PIX failure (full): ${error.failure}');
        state = state.copyWith(
          walletValidationInProgress: false,
          error: (error.failure.message.isNotEmpty == true
              ? error.failure.message
              : 'Technical error: ${error.failure}'),
        );
        return false;
      },
    );
  }
}

abstract class BuyTokenFormProvider {
  static final buyTokenForm = _buyTokenFormProvider;
}
