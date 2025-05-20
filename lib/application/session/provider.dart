import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stardpix/application/session/environment.dart';
import 'package:stardpix/application/session/state.dart';

part 'provider.g.dart';

@riverpod
Environment environment(Ref ref) => ref.watch(
      sessionNotifierProvider.select(
        (session) => session.environment,
      ),
    );

@riverpod
class SessionNotifier extends _$SessionNotifier {
  SessionNotifier();

  @override
  Session build() {
    return const Session(
      environment: Environment.devnet,
      accountAddress:
          '0x64b48806902a367c8598f4f95c305e8c1a1acba5f082d294a43793113115691',
    );
  }

  Future<void> connectWallet() async {}

  Future<void> update(FutureOr<Session> Function(Session previous) func) async {
    state = await func(state);
  }
}
