import 'package:chat/core/database/app_database.dart';
import 'package:chat/core/database/tables.dart';
import 'package:chat/core/providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class IncomingMessageHandler {
  final Ref _ref;
  IncomingMessageHandler(this._ref);

  Future<void> handle({
    required String messageId,
    required String senderPubKey,
    required Map<String, dynamic> data,
    required int contactId,
    required Contact contact,
  }) async {
    final chatRepo = _ref.read(chatRepositoryProvider);
    final contactsRepo = _ref.read(contactsRepositoryProvider);
    if (chatRepo == null || contactsRepo == null) return;

    switch (data['type']) {
      case 'text':
        await chatRepo.saveMessage(
          messageId: messageId,
          contactId: contactId,
          content: data['content'] as String,
          isFromMe: false,
        );
        break;
      case 'profile_sync':
        //TODO: after profile sync, I appear directly on his list screen. there needs to be an "accept request mechanism"
        final newAlias = data['nickname'] as String;
        if (contact.alias.startsWith('Unknown (')) {
          await contactsRepo.updateAlias(contactId, newAlias);
        }
        break;
      case 'messages_read':
        final readIds = (data['message_ids'] as List).cast<String>();
        await chatRepo.updateMessageStatus(
          readIds,
          MessageStatus.read,
          DateTime.now(),
        );
        break;
      default:
        debugPrint('Unknown message type: ${data['type']}');
    }
  }
}

final incomingMessageHandlerProvider = Provider<IncomingMessageHandler>((ref) {
  return IncomingMessageHandler(ref);
});
