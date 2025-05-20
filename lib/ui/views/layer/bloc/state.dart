import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stardpix/model/pixel.dart';

part 'state.freezed.dart';

enum Mode { erase, edit }

@freezed
class LayerFormState with _$LayerFormState {
  const factory LayerFormState({
    @Default('') String errorText,
    @Default(false) bool refreshInProgress,
    @Default(false) bool createInProgress,
    @Default([]) List<Pixel> pendingPixels,
    @Default(false) bool isBuyProcess,
    @Default(false) bool displayColorPicker,
    @Default(false) bool displayAbout,
    @Default(false) bool pickColor,
    @Default(0) int nbPixEdit,
    @Default(64) int maxPixEdit,
    @Default(Mode.edit) Mode mode,
    @Default(0) int timeLockInSeconds,
  }) = _LayerFormState;
  const LayerFormState._();

  bool get isControlsOk => errorText == '';
}
