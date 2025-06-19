import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:linkup/data/http_services/match_http_services/match_http_services.dart';
import 'package:linkup/data/models/chat_models/message_model.dart';
import 'package:linkup/data/models/chats_connection_model.dart';
import 'package:linkup/data/models/live_chat_data_model.dart';
import 'package:linkup/data/models/matches_connection_model.dart';
import 'package:linkup/data/websocket_services/chat_socket_services/chat_socket_service.dart';
import 'package:linkup/logic/bloc/lobby/lobby_bloc.dart';
import 'package:meta/meta.dart';

part 'connections_event.dart';
part 'connections_state.dart';

class ConnectionsBloc extends Bloc<ConnectionsEvent, ConnectionsState> {
  StreamSubscription<String>? _socketSubscription;

  ConnectionsBloc() : super(ConnectionsInitial()) {
    on<LoadConnectionsEvent>((event, emit) async {
      emit(ConnectionsLoading());
      try {
        Map<String, dynamic> connections = await MatchHttpServices().getConnections();

        _socketSubscription?.cancel();
        _socketSubscription = ChatSocketServices.messageStream.listen((raw) {
          final data = jsonDecode(raw);

          if (data["type"] == "chats") {
            if (data["chats_type"] == "message") {
              final recievedMessage = Message.fromJson(data);

              add(
                ReloadChatConnectionsEvent(
                  liveChatData: LiveChatDataModel(
                    from_: recievedMessage.from_,
                    chatRoomId: recievedMessage.chatRoomId,
                    message: recievedMessage.message,
                  ),
                ),
              );
            }
          }
        });

        emit(
          ConnectionsLoaded(
            matches: connections['matches'] as List<MatchesConnectionModel>,
            chats: connections['chats'] as List<ChatsConnectionModel>,
          ),
        );
      } on Exception catch (e, stackTrace) {
        log('Error loading connections: $e', stackTrace: stackTrace);
        emit(ConnectionsError());
      }
    });

    on<ReloadChatConnectionsEvent>((event, emit) async {
      final currentState = state;
      if (currentState is! ConnectionsLoaded) return;

      final List<ChatsConnectionModel> currentChatState = currentState.chats;
      final LiveChatDataModel? liveChatData = event.liveChatData;

      List<ChatsConnectionModel> updatedChats = List.from(currentChatState);

      if (liveChatData != null) {
        final index = updatedChats.indexWhere((chat) => chat.chatRoomId == liveChatData.chatRoomId);
        if (index != -1) {
          final oldChat = updatedChats[index];
          updatedChats[index] = oldChat.copyWith(message: liveChatData.message, unseenCounter: oldChat.unseenCounter + 1);
          emit(currentState.copyWith(chats: updatedChats));
        }
      }
    });

    on<MarkMessagesSeenEvent>((event, emit) {
      final currentState = state;
      if (currentState is! ConnectionsLoaded) {
        log('MarkMessagesSeenEvent: Current state is not ConnectionsLoaded, ignoring');
        return;
      }

      final List<ChatsConnectionModel> updatedChats = List.from(currentState.chats);
      final index = updatedChats.indexWhere((chat) => chat.chatRoomId == event.chatRoomId);

      if (index != -1) {
        final oldChat = updatedChats[index];
        log(
          'MarkMessagesSeenEvent: Found chatRoomId=${event.chatRoomId} with unseenCounter=${oldChat.unseenCounter}. Updating to ${event.decrementCounterTo}',
        );

        updatedChats[index] = oldChat.copyWith(unseenCounter: event.decrementCounterTo);

        emit(currentState.copyWith(chats: updatedChats));
        log('MarkMessagesSeenEvent: Emitted updated ConnectionsLoaded state with unseenCounter updated');
      } else {
        log('MarkMessagesSeenEvent: chatRoomId=${event.chatRoomId} not found in current chats');
      }
    });
  }

  @override
  Future<void> close() {
    _socketSubscription?.cancel();
    return super.close();
  }
}
