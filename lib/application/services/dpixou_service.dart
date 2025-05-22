// ignore_for_file: constant_identifier_names, parameter_assignments

import 'dart:async';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'package:stardpix/application/services/utils/contract_data_utils.dart';
import 'package:stardpix/model/core/failures.dart';
import 'package:stardpix/model/core/result.dart';
import 'package:starknet/starknet.dart';
import 'package:starknet_provider/starknet_provider.dart';

class DpixouService with ContractDataUtilsMixin {
  DpixouService({
    required this.provider,
    required String contractAddressStr,
    String? accountAddress,
    required String privateKey,
    required String strkTokenAddressStr,
  })  : contractAddress = Felt.fromHexString(contractAddressStr),
        account = accountAddress == null || accountAddress.isEmpty
            ? null
            : getAccount(
                accountAddress: Felt.fromHexString(accountAddress),
                privateKey: Felt.fromHexString(privateKey),
                nodeUri: provider.nodeUri,
              ),
        strkTokenAddress = Felt.fromHexString(strkTokenAddressStr);

  DpixouService.fromAccount({
    required this.provider,
    required String contractAddressStr,
    required this.account,
    required String strkTokenAddressStr,
  })  : contractAddress = Felt.fromHexString(contractAddressStr),
        strkTokenAddress = Felt.fromHexString(strkTokenAddressStr);

  factory DpixouService.defaultConfig() {
    final contractAddressStr = dotenv.env['DPIXOU_CONTRACT_ADDRESS'];
    final privateKeyStr = dotenv.env['STARKNET_PRIVATE_KEY'];
    final rpcUrlStr = dotenv.env['RPC_URL'];
    final strkTokenAddressStr = dotenv.env['STRK_TOKEN_CONTRACT_ADDRESS'];

    if (contractAddressStr == null ||
        privateKeyStr == null ||
        rpcUrlStr == null ||
        strkTokenAddressStr == null) {
      throw Exception('env variables not found');
    }

    return DpixouService(
      provider: JsonRpcProvider(nodeUri: Uri.parse(rpcUrlStr)),
      contractAddressStr: contractAddressStr,
      privateKey: privateKeyStr,
      strkTokenAddressStr: strkTokenAddressStr,
    );
  }
  final Logger logger = Logger('DpixouService');
  final JsonRpcProvider provider;
  final Felt contractAddress;
  final Account? account;
  final Felt strkTokenAddress;

  /// Buys PIX tokens with STRK tokens.
  /// Corresponds to the `buy_pix` function in dpixou.cairo.
  /// This function now handles both approval and the buy_pix call.
  Future<Result<void, Failure>> buyPix(BigInt amountStrk) async {
    if (account == null) {
      throw Exception('No account connected (wallet).');
    }
    logger
      ..info(
        '[DpixouService] Attempting buyPix with amountStrk: $amountStrk (raw BigInt)',
      )
      ..info(
        '[DpixouService] Account address: ${account!.accountAddress.toHexString()}',
      )
      ..info(
        '[DpixouService] Dpixou contract: ${contractAddress.toHexString()}',
      )
      ..info(
        '[DpixouService] STRK token contract: ${strkTokenAddress.toHexString()}',
      );

    return Result.guard(() async {
      try {
        if (amountStrk <= BigInt.zero) {
          logger.severe(
            '[DpixouService] Error: Amount STRK must be greater than 0.',
          );
          throw Exception('Amount STRK must be greater than 0');
        }

        final calls = <FunctionCall>[
          FunctionCall(
            contractAddress: strkTokenAddress,
            entryPointSelector: getSelectorByName('approve'),
            calldata: [
              contractAddress, // spender: Dpixou contract
              ...bigIntToU256FeltList(amountStrk), // amount to approve
            ],
          ),
          FunctionCall(
            contractAddress: contractAddress, // Dpixou contract
            entryPointSelector: getSelectorByName('buy_pix'),
            calldata: [
              ...bigIntToU256FeltList(amountStrk), // amount_strk for buy_pix
            ],
          ),
        ];

        logger.info(
          '[DpixouService] Prepared calls for account.execute: ',
        );
        for (var i = 0; i < calls.length; i++) {
          logger
            ..info(
              '  Call ${i + 1}:',
            )
            ..info(
              '    Contract: ${calls[i].contractAddress.toHexString()}',
            )
            ..info(
              '    Selector: ${calls[i].entryPointSelector.toHexString()} (${selectorToName(calls[i].entryPointSelector)})',
            )
            ..info(
              '    Calldata: ${calls[i].calldata.map((f) => f.toHexString()).toList()}',
            );
        }
        logger.info(
          '[DpixouService] Account provider nodeUri before execute: ${(account!.provider as JsonRpcProvider).nodeUri}',
        );
        final response = await account!.execute(functionCalls: calls);
        logger.info(
          '[DpixouService] account.execute response: $response',
        );

        final txSubmitResult = response.when(
          result: (r) => r,
          error: (err) {
            logger.severe(
              '[DpixouService] Error from account.execute: ${err.message} (Code: ${err.code})',
            );
            throw Exception(
              'Failed to execute buy PIX transaction: ${err.message}',
            );
          },
        );

        final transactionHashString = txSubmitResult.transaction_hash;

        logger
          ..info(
            '[DpixouService] Transaction hash: $transactionHashString',
          )
          ..info(
            '[DpixouService] Waiting for transaction acceptance...',
          );
        await waitForAcceptance(
          transactionHash: transactionHashString,
          provider: provider,
        );
        logger.info(
          '[DpixouService] Transaction accepted.',
        );
        return;
      } catch (e, stack) {
        logger.severe(
          '[DpixouService] Error in buyPix (outer catch): $e\n$stack',
        );
        if (e is Exception &&
            e.toString().contains('Failed to execute buy PIX transaction')) {
          rethrow;
        }
        // Propager le message d'erreur dans Failure.other
        throw Exception('Failed to buy PIX: $e');
      }
    });
  }

  String selectorToName(Felt selector) {
    final selectorHex = selector.toHexString();
    final knownSelectors = {
      getSelectorByName('approve').toHexString(): 'approve',
      getSelectorByName('buy_pix').toHexString(): 'buy_pix',
      getSelectorByName('get_nb_pix_for_strk').toHexString():
          'get_nb_pix_for_strk',
      getSelectorByName('get_nb_strk_for_pix').toHexString():
          'get_nb_strk_for_pix',
    };
    return knownSelectors[selectorHex] ?? selectorHex;
  }

  /// Estimates the fee for buying PIX tokens with STRK.
  Future<FeeEstimations?> estimateBuyPixFee(BigInt amountStrk) async {
    if (amountStrk <= BigInt.zero) {
      return null;
    }
    logger
      ..info(
        '[DpixouService] Estimating fee for amountStrk: $amountStrk',
      )
      ..info(
        '[DpixouService] Using STRK token: ${strkTokenAddress.toHexString()} and Dpixou: ${contractAddress.toHexString()} for estimation',
      );
    try {
      final calls = <FunctionCall>[
        FunctionCall(
          contractAddress: strkTokenAddress,
          entryPointSelector: getSelectorByName('approve'),
          calldata: [
            contractAddress, // spender: Dpixou contract
            ...bigIntToU256FeltList(amountStrk), // amount to approve
          ],
        ),
        FunctionCall(
          contractAddress: contractAddress, // Dpixou contract
          entryPointSelector: getSelectorByName('buy_pix'),
          calldata: [
            ...bigIntToU256FeltList(amountStrk), // amount_strk for buy_pix
          ],
        ),
      ];

      logger.info(
        '[DpixouService] Estimating fee with calls: approve then buy_pix',
      );
      final feeEstimation = await account!.getEstimateMaxFeeForInvokeTx(
        functionCalls: calls,
      );

      logger.info(
        '[DpixouService] Estimated fee result: maxFee=${feeEstimation.maxFee.toBigInt()}, unit=${feeEstimation.unit}',
      );
      return feeEstimation;
    } catch (e, stack) {
      logger.severe(
        '[DpixouService] Error in estimateBuyPixFee: $e\n$stack',
      );
      return null;
    }
  }

  /// Gets the number of PIX tokens for a given amount of STRK tokens.
  /// Corresponds to the `get_nb_pix_for_strk` function in dpixou.cairo.
  Future<BigInt> getNbPixForStrk(BigInt amountStrk) async {
    try {
      logger.info(
        'DpixouService.getNbPixForStrk: Calling with amountStrk: $amountStrk',
      );
      final functionCall = FunctionCall(
        contractAddress: contractAddress,
        entryPointSelector: getSelectorByName('get_nb_pix_for_strk'),
        calldata: [
          ...bigIntToU256FeltList(amountStrk),
        ],
      );

      logger.info(
        'DpixouService.getNbPixForStrk: Prepared FunctionCall: ${functionCall.contractAddress.toHexString()} / ${functionCall.entryPointSelector.toHexString()} / Calldata count: ${functionCall.calldata.length}, First element: ${functionCall.calldata.isNotEmpty ? functionCall.calldata.first.toHexString() : 'N/A'}',
      );

      final response = await provider.call(
        request: functionCall,
        blockId: BlockId.latest,
      );
      logger.info(
        'DpixouService.getNbPixForStrk: provider.call completed.',
      );

      final result = response.when(
        result: (data) {
          logger.info(
            'DpixouService.getNbPixForStrk: response.when -> result (List<Felt>): $data',
          );
          if (data.isEmpty) {
            logger.severe(
              'DpixouService.getNbPixForStrk: Data is empty.',
            );
            throw Exception(
              'Empty response from get_nb_pix_for_strk (data was empty)',
            );
          }
          logger.info(
            'DpixouService.getNbPixForStrk: Data is NOT empty. First element (Felt): ${data.first.toHexString()}',
          );
          return data;
        },
        error: (err) {
          logger.severe(
            'DpixouService.getNbPixForStrk: response.when -> error. Code: ${err.code}, Message: ${err.message}',
          );
          throw Exception(
            'Failed to get PIX for STRK (from .when error branch): Code: ${err.code}, Message: ${err.message}',
          );
        },
      );
      if (result.isEmpty) {
        logger.severe(
          'DpixouService.getNbPixForStrk: Result (after .when processing) is empty.',
        );
        throw Exception(
          'Empty response from get_nb_pix_for_strk (result was empty post-when)',
        );
      }
      logger.info(
        'DpixouService.getNbPixForStrk: Result (after .when processing) is NOT empty. First element (Felt): ${result.first.toHexString()}',
      );
      return result.first.toBigInt();
    } catch (e) {
      if (e.toString().contains('Failed to get PIX for STRK')) {
        logger.severe(
          'DpixouService.getNbPixForStrk: Rethrowing specific error: $e',
        );
        rethrow;
      }
      logger.severe(
        'DpixouService.getNbPixForStrk: Generic catch block: $e',
      );
      throw Exception('Failed to get PIX for STRK (generic catch): $e');
    }
  }

  /// Gets the number of STRK tokens for a given amount of PIX tokens.
  /// Corresponds to the `get_nb_strk_for_pix` function in dpixou.cairo.
  Future<BigInt> getNbStrkForPix(BigInt amountPix) async {
    try {
      final response = await provider.call(
        request: FunctionCall(
          contractAddress: contractAddress,
          entryPointSelector: getSelectorByName('get_nb_strk_for_pix'),
          calldata: [
            ...bigIntToU256FeltList(amountPix),
          ],
        ),
        blockId: BlockId.latest,
      );

      final result = response.when(
        result: (data) => data,
        error: (err) => throw Exception(
          'Failed to get STRK for PIX: ${err.message}',
        ),
      );

      if (result.isEmpty) {
        throw Exception('Empty response from get_nb_strk_for_pix');
      }
      return result.first.toBigInt();
    } catch (e) {
      logger.severe(
        'Error in getNbStrkForPix: $e',
      );
      throw Exception('Failed to get STRK for PIX: $e');
    }
  }
}

final defaultDpixouService = DpixouService.defaultConfig();

Future<Result<void, Failure>> buyPix(BigInt amountStrk) =>
    defaultDpixouService.buyPix(amountStrk);
Future<BigInt> getNbPixForStrk(BigInt amountStrk) =>
    defaultDpixouService.getNbPixForStrk(amountStrk);
Future<BigInt> getNbStrkForPix(BigInt amountPix) =>
    defaultDpixouService.getNbStrkForPix(amountPix);
Future<FeeEstimations?> estimateBuyPixFee(BigInt amountStrk) =>
    defaultDpixouService.estimateBuyPixFee(amountStrk);
