// ignore_for_file: constant_identifier_names, parameter_assignments

import 'dart:async';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'package:stardpix/application/services/utils/contract_data_utils.dart';
import 'package:stardpix/model/core/failures.dart';
import 'package:stardpix/model/core/result.dart';
import 'package:stardpix/model/pixel.dart';
import 'package:starknet/starknet.dart';
import 'package:starknet_provider/starknet_provider.dart';

class PixelWarService with ContractDataUtilsMixin {
  PixelWarService({
    required this.provider,
    required String contractAddressStr,
    String? accountAddress,
    required String privateKey,
    required this.pixTokenAddress,
  })  : contractAddress = Felt.fromHexString(contractAddressStr),
        account = accountAddress == null || accountAddress.isEmpty
            ? null
            : getAccount(
                accountAddress: Felt.fromHexString(accountAddress),
                privateKey: Felt.fromHexString(privateKey),
                nodeUri: provider.nodeUri,
              );

  PixelWarService.fromAccount({
    required this.provider,
    required String contractAddressStr,
    required this.account,
    required String pixTokenAddress,
  })  : contractAddress = Felt.fromHexString(contractAddressStr),
        pixTokenAddress = Felt.fromHexString(pixTokenAddress);

  factory PixelWarService.defaultConfig() {
    final contractAddressStr = dotenv.env['PIXELWAR_CONTRACT_ADDRESS'];
    final privateKeyStr = dotenv.env['STARKNET_PRIVATE_KEY'];
    final rpcUrlStr = dotenv.env['RPC_URL'];
    final pixTokenAddressStr = dotenv.env['PIX_TOKEN_CONTRACT_ADDRESS'];

    if (contractAddressStr == null ||
        privateKeyStr == null ||
        rpcUrlStr == null ||
        pixTokenAddressStr == null) {
      throw Exception('Environment variables not found for PixelWarService');
    }

    return PixelWarService(
      provider: JsonRpcProvider(nodeUri: Uri.parse(rpcUrlStr)),
      contractAddressStr: contractAddressStr,
      privateKey: privateKeyStr,
      pixTokenAddress: Felt.fromHexString(pixTokenAddressStr),
    );
  }
  final Logger logger = Logger('PixelWarService');
  final JsonRpcProvider provider;
  final Felt contractAddress;
  final Account? account;
  final Felt pixTokenAddress;

  static const int MAX_PIXELS_PER_TX = 64;
  static const int MAX_X = 300;
  static const int MAX_Y = 100;

  bool _validateCoordinates(int x, int y) {
    return x >= 0 && x < MAX_X && y >= 0 && y < MAX_Y;
  }

  Future<List<Pixel>> getPixels() async {
    final response = await provider.call(
      request: FunctionCall(
        contractAddress: contractAddress,
        entryPointSelector: getSelectorByName('get_all_pixels'),
        calldata: [],
      ),
      blockId: BlockId.latest,
    );

    final result = response.when(
      result: (data) => data,
      error: (err) => throw Exception(
        'Failed to retrieve pixels: ${err.message}',
      ),
    );

    final pixels = <Pixel>[];
    if (result.isEmpty) return pixels;

    var arrayLenHex = result[0].toHexString();
    if (arrayLenHex.startsWith('0x')) {
      arrayLenHex = arrayLenHex.substring(2);
    }
    final arrayLen = int.parse(arrayLenHex, radix: 16);

    // Process each pixel (3 values per pixel: x, y, color)
    for (var i = 0; i < arrayLen; i++) {
      final index = 1 +
          i * 3; // Start from 1 (after array length) and skip 3 values per pixel
      if (index + 2 >= result.length) break;

      var xHex = result[index].toHexString();
      if (xHex.startsWith('0x')) {
        xHex = xHex.substring(2);
      }
      final x = int.parse(xHex, radix: 16);

      var yHex = result[index + 1].toHexString();
      if (yHex.startsWith('0x')) {
        yHex = yHex.substring(2);
      }
      final y = int.parse(yHex, radix: 16);

      var colorFeltHex = result[index + 2].toHexString();
      if (colorFeltHex.startsWith('0x')) {
        colorFeltHex = colorFeltHex.substring(2);
      }
      final colorFelt = int.parse(colorFeltHex, radix: 16);

      pixels.add(
        Pixel(
          dx: x,
          dy: y,
          color: feltToColor(colorFelt),
        ),
      );
    }

    return pixels;
  }

  Future<Result<void, Failure>> addPixels(List<Pixel> pixels) async {
    return Result.guard(() async {
      if (account == null) {
        throw Exception('No account connected (wallet).');
      }

      if (pixels.isEmpty) {
        throw Exception('Pixel list cannot be empty');
      }

      if (pixels.length > MAX_PIXELS_PER_TX) {
        throw Exception(
          'Cannot add more than $MAX_PIXELS_PER_TX pixels in a single transaction',
        );
      }

      for (final pixel in pixels) {
        if (!_validateCoordinates(pixel.dx ?? 0, pixel.dy ?? 0)) {
          throw Exception(
            'Invalid coordinates for pixel: (${pixel.dx}, ${pixel.dy})',
          );
        }
      }

      final unlockTime =
          await getUnlockTime(account!.accountAddress.toHexString());
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      if (now < unlockTime) {
        throw Exception(
          'Cooldown active: you cannot place pixels before $unlockTime (current timestamp: $now)',
        );
      }

      final onePixInWei = BigInt.from(10).pow(18);
      final totalPixToBurn = onePixInWei * BigInt.from(pixels.length);

      logger.info(
        'Approving PixelWar contract (${contractAddress.toHexString()}) to spend $totalPixToBurn PIX from account ${account!.accountAddress.toHexString()} for token ${pixTokenAddress.toHexString()}',
      );
      final approveResponse = await account!.execute(
        functionCalls: [
          FunctionCall(
            contractAddress: pixTokenAddress,
            entryPointSelector: getSelectorByName('approve'),
            calldata: [
              contractAddress,
              ...bigIntToU256FeltList(totalPixToBurn),
            ],
          ),
        ],
      );
      await approveResponse.when(
        result: (result) async {
          logger.info('PIX Approve successful: ${result.transaction_hash}');
          await waitForAcceptance(
            transactionHash: result.transaction_hash,
            provider: provider,
          );
        },
        error: (err) => throw Exception(
          'Failed to approve PIX for PixelWar: ${err.message}',
        ),
      );
      logger.info('PIX Approved for PixelWar contract.');

      // Check ETH balance before estimation/execution
      // Default ETH devnet address (OpenZeppelin ETH token)
      final ethTokenAddress = Felt.fromHexString(
        dotenv.env['ETH_TOKEN_CONTRACT_ADDRESS'] ??
            '0x49D36570D4E46F48E99674BD3FCC84644DDD6B96F7C741B1562B82F9E004DC7',
      );
      final ethBalanceResponse = await provider.call(
        request: FunctionCall(
          contractAddress: ethTokenAddress,
          entryPointSelector: getSelectorByName('balanceOf'),
          calldata: [account!.accountAddress],
        ),
        blockId: BlockId.latest,
      );
      final ethBalance = ethBalanceResponse.when(
        result: (data) => data.isNotEmpty ? data.first.toBigInt() : BigInt.zero,
        error: (err) {
          logger.severe(
            'Error fetching ETH balance: Code ${err.code}, Message: ${err.message}',
          );
          return BigInt.zero;
        },
      );
      logger.info(
        'Account ETH balance ${account!.accountAddress.toHexString()}: $ethBalance wei',
      );

      // Arbitrary threshold of 0.0001 ETH (1e12 wei)
      if (ethBalance < BigInt.from(10).pow(12)) {
        throw Exception(
          'ETH balance too low to pay fees (balance: $ethBalance wei)',
        );
      }

      // Convert pixels to calldata format
      // Format for Array<Pixel>: [array_len, x1, y1, color1, x2, y2, color2, ...]
      final pixelCalldata = <Felt>[
        Felt.fromIntString(pixels.length.toString()),
      ];

      for (final pixel in pixels) {
        final colorInt = pixel.color != null ? colorToFelt(pixel.color!) : 0;
        pixelCalldata
          ..add(Felt.fromIntString((pixel.dx ?? 0).toString()))
          ..add(Felt.fromIntString((pixel.dy ?? 0).toString()))
          ..add(Felt.fromIntString(colorInt.toString()));
      }

      try {
        logger.info('pixelCalldata: $pixelCalldata');

        // Estimate fees before execution
        try {
          final feeEstimate = await account!.getEstimateMaxFeeForInvokeTx(
            functionCalls: [
              FunctionCall(
                contractAddress: contractAddress,
                entryPointSelector: getSelectorByName('add_pixels'),
                calldata: pixelCalldata,
              ),
            ],
          );
          logger.info(
            'Estimated fees for add_pixels: ${feeEstimate.maxFee.toHexString()} wei',
          );
        } catch (e, stack) {
          logger
            ..severe('Error estimating fees: $e')
            ..severe('Stack trace for fee estimation: $stack');
        }

        logger.info(
          'Calling account.execute for account: ${account!.accountAddress.toHexString()}',
        );
        final invokeResponse = await account!.execute(
          functionCalls: [
            FunctionCall(
              contractAddress: contractAddress,
              entryPointSelector: getSelectorByName('add_pixels'),
              calldata: pixelCalldata,
            ),
          ],
        );

        await invokeResponse.when(
          result: (invokeTxResult) async {
            final txHashString = invokeTxResult.transaction_hash;
            logger.info('txHash (String from result): $txHashString');

            await waitForAcceptance(
              transactionHash: txHashString,
              provider: provider,
            );

            logger.info('Transaction for addPixels submitted and accepted.');
          },
          error: (jsonRpcApiError) {
            var errorMessage = jsonRpcApiError.message;
            errorMessage =
                'Code: ${jsonRpcApiError.code}, Message: $errorMessage';
            logger.severe(
              'RPC error reported by invokeResponse.when: $errorMessage',
            );
            throw Exception(
              'Submission failed (RPC error): $errorMessage',
            );
          },
        );
      } catch (e, stackTrace) {
        logger
          ..severe('Generic exception caught in addPixels: $e')
          ..severe('Stack trace: $stackTrace');
        rethrow;
      }
    });
  }

  Future<int> getPixelColor(int x, int y) async {
    if (!_validateCoordinates(x, y)) {
      throw Exception(
        'Invalid coordinates: x must be between 0 and ${MAX_X - 1}, y between 0 and ${MAX_Y - 1}',
      );
    }

    final response = await provider.call(
      request: FunctionCall(
        contractAddress: contractAddress,
        entryPointSelector: getSelectorByName('get_pixel_color'),
        calldata: [
          Felt.fromIntString(x.toString()),
          Felt.fromIntString(y.toString()),
        ],
      ),
      blockId: BlockId.latest,
    );

    final result = response.when(
      result: (data) => data,
      error: (err) => throw Exception(
        'Failed to retrieve color: ${err.message}',
      ),
    );

    var hexColor = result.first.toHexString();
    if (hexColor.startsWith('0x')) {
      hexColor = hexColor.substring(2);
    }
    return int.parse(hexColor, radix: 16);
  }

  Future<int> getUnlockTime(String userAddress) async {
    final response = await provider.call(
      request: FunctionCall(
        contractAddress: contractAddress,
        entryPointSelector: getSelectorByName('get_unlock_time'),
        calldata: [Felt.fromHexString(userAddress)],
      ),
      blockId: BlockId.latest,
    );

    final result = response.when(
      result: (data) => data,
      error: (err) {
        logger.severe(
          'Failed to retrieve unlock time: ${err.message}',
        );
        throw Exception(
          'Failed to retrieve unlock time: ${err.message}',
        );
      },
    );

    if (result.isEmpty) {
      throw Exception('Empty response from get_unlock_time');
    }
    return result.first.toInt();
  }
}

final defaultService = PixelWarService.defaultConfig();

Future<Result<void, Failure>> addPixels(List<Pixel> pixels) =>
    defaultService.addPixels(pixels);
Future<int> getPixelColor(int x, int y) => defaultService.getPixelColor(x, y);
Future<int> getUnlockTime(String userAddress) =>
    defaultService.getUnlockTime(userAddress);
Future<List<Pixel>> getPixels() => defaultService.getPixels();
