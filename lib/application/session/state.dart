import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stardpix/application/session/environment.dart';

part 'state.freezed.dart';

@freezed
class Session with _$Session {
  const factory Session({
    required Environment environment,
    @Default('') String nameAccount,
    @Default('') String accountAddress,
    @Default('') String error,
  }) = _Session;
  const Session._();

  bool get isConnected =>
      // TODO(reddwarf03): Manage connection
      true;
}
