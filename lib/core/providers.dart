import 'package:chat/core/network/websocket_service.dart';
import 'package:chat/features/chat/chat_repository.dart';
import 'package:chat/features/contacts/contacts_repository.dart';
import 'package:chat/features/key_management/key_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'security/crypto_service.dart';
import 'security/secure_storage_service.dart';
import 'database/app_database.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final cryptoServiceProvider = Provider<CryptoService>((ref) {
  throw UnimplementedError(
    'cryptoServiceProvider must be overridden in main.dart',
  );
});

final databaseProvider = FutureProvider<AppDatabase>((ref) async {
  final secureStorage = ref.read(secureStorageProvider);

  final activePublicKey = ref.watch(
    keyControllerProvider.select((state) => state.publicKeyHex),
  );

  if (activePublicKey == null || activePublicKey.isEmpty) {
    throw Exception('Cannot open database: No active account.');
  }
  final dbKey = await secureStorage.getOrCreateDatabaseKey(activePublicKey);

  final db = AppDatabase(activePublicKey, dbKey);

  ref.onDispose(() {
    db.close();
  });

  return db;
});

final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService();

  ref.onDispose(() {
    service.disconnect();
  });

  return service;
});

final chatRepositoryProvider = Provider<MessagesRepository?>((ref) {
  final db = ref.watch(databaseProvider).asData?.value;
  return db != null ? MessagesRepository(db) : null;
});

final contactsRepositoryProvider = Provider<ContactsRepository?>((ref) {
  final db = ref.watch(databaseProvider).asData?.value;
  return db != null ? ContactsRepository(db) : null;
});
