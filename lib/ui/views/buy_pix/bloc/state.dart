import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:starknet/starknet.dart';

part 'state.freezed.dart';

@freezed
class BuyTokenFormState with _$BuyTokenFormState {
  const factory BuyTokenFormState({
    String? error,
    @Default(false) bool walletValidationInProgress,
    FeeEstimations? estimatedFee,
    int? selectedPixAmount,
    BigInt? correspondingStrkAmount,
    @Default(false) bool isLoadingFee,
  }) = _BuyTokenFormState;
  const BuyTokenFormState._();
}
