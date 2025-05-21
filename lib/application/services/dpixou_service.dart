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
    required String friTokenAddressStr,
  })  : contractAddress = Felt.fromHexString(contractAddressStr),
        account = accountAddress == null || accountAddress.isEmpty
            ? null
            : getAccount(
                accountAddress: Felt.fromHexString(accountAddress),
                privateKey: Felt.fromHexString(privateKey),
                nodeUri: provider.nodeUri,
              ),
        friTokenAddress = Felt.fromHexString(friTokenAddressStr);

  DpixouService.fromAccount({
    required this.provider,
    required String contractAddressStr,
    required this.account,
    required String friTokenAddressStr,
  })  : contractAddress = Felt.fromHexString(contractAddressStr),
        friTokenAddress = Felt.fromHexString(friTokenAddressStr);

  factory DpixouService.defaultConfig() {
    final contractAddressStr = dotenv.env['DPIXOU_CONTRACT_ADDRESS'];
    final privateKeyStr = dotenv.env['STARKNET_PRIVATE_KEY'];
    final rpcUrlStr = dotenv.env['RPC_URL'];
    final friTokenAddressStr = dotenv.env['FRI_TOKEN_CONTRACT_ADDRESS'];

    if (contractAddressStr == null ||
        privateKeyStr == null ||
        rpcUrlStr == null ||
        friTokenAddressStr == null) {
      throw Exception('env variables not found');
    }

    return DpixouService(
      provider: JsonRpcProvider(nodeUri: Uri.parse(rpcUrlStr)),
      contractAddressStr: contractAddressStr,
      privateKey: privateKeyStr,
      friTokenAddressStr: friTokenAddressStr,
    );
  }
  final Logger logger = Logger('DpixouService');
  final JsonRpcProvider provider;
  final Felt contractAddress;
  final Account? account;
  final Felt friTokenAddress;

  /// Buys PIX tokens with FRI tokens.
  /// Corresponds to the `buy_pix` function in dpixou.cairo.
  /// This function now handles both approval and the buy_pix call.
  Future<Result<void, Failure>> buyPix(BigInt amountFri) async {
    if (account == null) {
      throw Exception('No account connected (wallet).');
    }
    logger
      ..info(
        '[DpixouService] Attempting buyPix with amountFri: $amountFri (raw BigInt)',
      )
      ..info(
        '[DpixouService] Account address: ${account!.accountAddress.toHexString()}',
      )
      ..info(
        '[DpixouService] Dpixou contract: ${contractAddress.toHexString()}',
      )
      ..info(
        '[DpixouService] FRI token contract: ${friTokenAddress.toHexString()}',
      );

    return Result.guard(() async {
      try {
        if (amountFri <= BigInt.zero) {
          logger.severe(
            '[DpixouService] Error: Amount FRI must be greater than 0.',
          );
          throw Exception('Amount FRI must be greater than 0');
        }

        final calls = <FunctionCall>[
          FunctionCall(
            contractAddress: friTokenAddress,
            entryPointSelector: getSelectorByName('approve'),
            calldata: [
              contractAddress, // spender: Dpixou contract
              ...bigIntToU256FeltList(amountFri), // amount to approve
            ],
          ),
          FunctionCall(
            contractAddress: contractAddress, // Dpixou contract
            entryPointSelector: getSelectorByName('buy_pix'),
            calldata: [
              ...bigIntToU256FeltList(amountFri), // amount_fri for buy_pix
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
      getSelectorByName('get_nb_pix_for_fri').toHexString():
          'get_nb_pix_for_fri',
      getSelectorByName('get_nb_fri_for_pix').toHexString():
          'get_nb_fri_for_pix',
    };
    return knownSelectors[selectorHex] ?? selectorHex;
  }

  /// Estimates the fee for buying PIX tokens with FRI.
  Future<FeeEstimations?> estimateBuyPixFee(BigInt amountFri) async {
    if (amountFri <= BigInt.zero) {
      return null;
    }
    logger
      ..info(
        '[DpixouService] Estimating fee for amountFri: $amountFri',
      )
      ..info(
        '[DpixouService] Using FRI token: ${friTokenAddress.toHexString()} and Dpixou: ${contractAddress.toHexString()} for estimation',
      );
    try {
      final calls = <FunctionCall>[
        FunctionCall(
          contractAddress: friTokenAddress,
          entryPointSelector: getSelectorByName('approve'),
          calldata: [
            contractAddress, // spender: Dpixou contract
            ...bigIntToU256FeltList(amountFri), // amount to approve
          ],
        ),
        FunctionCall(
          contractAddress: contractAddress, // Dpixou contract
          entryPointSelector: getSelectorByName('buy_pix'),
          calldata: [
            ...bigIntToU256FeltList(amountFri), // amount_fri for buy_pix
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
    } catch (e) {
      logger.severe(
        '[DpixouService] Error in estimateBuyPixFee: $e',
      );
      return null;
    }
  }

  /// Gets the number of PIX tokens for a given amount of FRI tokens.
  /// Corresponds to the `get_nb_pix_for_fri` function in dpixou.cairo.
  Future<BigInt> getNbPixForFri(BigInt amountFri) async {
    try {
      logger.info(
        'DpixouService.getNbPixForFri: Calling with amountFri: $amountFri',
      );
      final functionCall = FunctionCall(
        contractAddress: contractAddress,
        entryPointSelector: getSelectorByName('get_nb_pix_for_fri'),
        calldata: [
          ...bigIntToU256FeltList(amountFri),
        ],
      );

      logger.info(
        'DpixouService.getNbPixForFri: Prepared FunctionCall: ${functionCall.contractAddress.toHexString()} / ${functionCall.entryPointSelector.toHexString()} / Calldata count: ${functionCall.calldata.length}, First element: ${functionCall.calldata.isNotEmpty ? functionCall.calldata.first.toHexString() : 'N/A'}',
      );

      final response = await provider.call(
        request: functionCall,
        blockId: BlockId.latest,
      );
      logger.info(
        'DpixouService.getNbPixForFri: provider.call completed.',
      );

      final result = response.when(
        result: (data) {
          logger.info(
            'DpixouService.getNbPixForFri: response.when -> result (List<Felt>): $data',
          );
          if (data.isEmpty) {
            logger.severe(
              'DpixouService.getNbPixForFri: Data is empty.',
            );
            throw Exception(
              'Empty response from get_nb_pix_for_fri (data was empty)',
            );
          }
          logger.info(
            'DpixouService.getNbPixForFri: Data is NOT empty. First element (Felt): ${data.first.toHexString()}',
          );
          return data;
        },
        error: (err) {
          logger.severe(
            'DpixouService.getNbPixForFri: response.when -> error. Code: ${err.code}, Message: ${err.message}',
          );
          throw Exception(
            'Failed to get PIX for FRI (from .when error branch): Code: ${err.code}, Message: ${err.message}',
          );
        },
      );
      if (result.isEmpty) {
        logger.severe(
          'DpixouService.getNbPixForFri: Result (after .when processing) is empty.',
        );
        throw Exception(
          'Empty response from get_nb_pix_for_fri (result was empty post-when)',
        );
      }
      logger.info(
        'DpixouService.getNbPixForFri: Result (after .when processing) is NOT empty. First element (Felt): ${result.first.toHexString()}',
      );
      return result.first.toBigInt();
    } catch (e) {
      if (e.toString().contains('Failed to get PIX for FRI')) {
        logger.severe(
          'DpixouService.getNbPix_for_fri: Rethrowing specific error: $e',
        );
        rethrow;
      }
      logger.severe(
        'DpixouService.getNbPixForFri: Generic catch block: $e',
      );
      throw Exception('Failed to get PIX for FRI (generic catch): $e');
    }
  }

  /// Gets the number of FRI tokens for a given amount of PIX tokens.
  /// Corresponds to the `get_nb_fri_for_pix` function in dpixou.cairo.
  Future<BigInt> getNbFriForPix(BigInt amountPix) async {
    try {
      final response = await provider.call(
        request: FunctionCall(
          contractAddress: contractAddress,
          entryPointSelector: getSelectorByName('get_nb_fri_for_pix'),
          calldata: [
            ...bigIntToU256FeltList(amountPix),
          ],
        ),
        blockId: BlockId.latest,
      );

      final result = response.when(
        result: (data) => data,
        error: (err) => throw Exception(
          'Failed to get FRI for PIX: ${err.message}',
        ),
      );

      if (result.isEmpty) {
        throw Exception('Empty response from get_nb_fri_for_pix');
      }
      return result.first.toBigInt();
    } catch (e) {
      logger.severe(
        'Error in getNbFriForPix: $e',
      );
      throw Exception('Failed to get FRI for PIX: $e');
    }
  }
}

final defaultDpixouService = DpixouService.defaultConfig();

Future<Result<void, Failure>> buyPix(BigInt amountFri) =>
    defaultDpixouService.buyPix(amountFri);
Future<BigInt> getNbPixForFri(BigInt amountFri) =>
    defaultDpixouService.getNbPixForFri(amountFri);
Future<BigInt> getNbFriForPix(BigInt amountPix) =>
    defaultDpixouService.getNbFriForPix(amountPix);
Future<FeeEstimations?> estimateBuyPixFee(BigInt amountFri) =>
    defaultDpixouService.estimateBuyPixFee(amountFri);
