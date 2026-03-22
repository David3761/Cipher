import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tor/tor.dart';

enum TorStatus { stopped, bootstrapping, ready, error }

class TorNotifier extends AsyncNotifier<TorStatus> {
  @override
  Future<TorStatus> build() async => TorStatus.stopped;

  Future<void> start() async {
    state = const AsyncData(TorStatus.bootstrapping);
    try {
      await Tor.init();
      await Tor.instance.start();
      state = const AsyncData(TorStatus.ready);
      debugPrint('Tor started on port ${Tor.instance.port}');
    } catch (e) {
      debugPrint('Tor failed to start: $e');
      state = const AsyncData(TorStatus.error);
    }
  }

  Future<void> stop() async {
    try {
      await Tor.instance.stop();
    } catch (e) {
      debugPrint('Tor failed to stop: $e');
    }
    state = const AsyncData(TorStatus.stopped);
  }

  bool get isReady => state.value == TorStatus.ready;
  int get port => Tor.instance.port;
}

final torProvider = AsyncNotifierProvider<TorNotifier, TorStatus>(
  TorNotifier.new,
);
