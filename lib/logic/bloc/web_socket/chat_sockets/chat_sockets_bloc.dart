import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:isar/isar.dart';
import 'package:linkup/data/isar_classes/message_table.dart';
import 'package:linkup/data/isar_classes/unsent_messages_table.dart';
import 'package:linkup/data/models/chat_models/message_model.dart';
import 'package:linkup/data/websocket_services/chat_socket_services/chat_socket_service.dart';
import 'package:meta/meta.dart';

part 'chat_sockets_event.dart';
part 'chat_sockets_state.dart';

class ChatSocketsBloc extends Bloc<ChatSocketsEvent, ChatSocketsState> {
  final Isar isar;

  StreamSubscription<bool>? _statusSubscription;
  final String _logTag = "ChatSocketsBloc";

  ChatSocketsBloc({required this.isar}) : super(ChatSocketsInitial()) {
    on<LoadChatSocketsEvent>((event, emit) async {
      emit(ChatSocketsConnecting());
      try {
        await ChatSocketServices.instance().connect();

        _statusSubscription?.cancel();
        _statusSubscription = ChatSocketServices.chatsConnectionStatusStream.listen((connected) async {
          log("WebSocket connected: $connected", name: _logTag);
          if (connected == true) {
            final allMessages = await isar.unsentMessagesTables.where().findAll();

            for (UnsentMessagesTable msg in allMessages) {
              try {
                Message message = msg.toMessage();
                ChatSocketServices.instance().sendMessage(message.toJson());
                message.copyWith(isSent: true);

                await isar.writeTxn(() async {
                  await isar.messageTables.put(MessageTable.fromMessage(message));
                  await isar.unsentMessagesTables.delete(msg.id);
                });
              } catch (e) {
                log("Failed to resend unsent message: $e", name: _logTag);
              }
            }
          }
        });

        emit(ChatSocketsConnected());
      } catch (e) {
        log("ChatSockets error: $e", name: _logTag);
        emit(ChatSocketsError());
      }
    });
  }
}
