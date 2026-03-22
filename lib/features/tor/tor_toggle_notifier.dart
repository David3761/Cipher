import 'package:chat/core/providers.dart';
import 'package:chat/features/key_management/key_controller.dart';
import 'package:chat/features/tor/tor_service.dart';
import 'package:chat/core/network/connection_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TorToggleNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final storage = ref.read(secureStorageProvider);
    final pubKey = ref.watch(
      keyControllerProvider.select((s) => s.publicKeyHex),
    );
    if (pubKey == null) return false;
    return await storage.getTorEnabled(pubKey);
  }

  Future<void> toggle(BuildContext context) async {
    final storage = ref.read(secureStorageProvider);
    final pubKey = ref.read(keyControllerProvider).publicKeyHex;
    if (pubKey == null) return;

    final current = state.value ?? false;
    final next = !current;

    await storage.setTorEnabled(pubKey, next);
    state = AsyncData(next);

    if (next) {
      await ref.read(torProvider.notifier).start();
    } else {
      await ref.read(torProvider.notifier).stop();
    }

    ref.invalidate(connectionControllerProvider);
  }
}

final torToggleProvider = AsyncNotifierProvider<TorToggleNotifier, bool>(
  TorToggleNotifier.new,
);
