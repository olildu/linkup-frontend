import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:isar/isar.dart';
import 'package:linkup/data/enums/message_type_enum.dart';
import 'package:linkup/data/http_services/match_http_services/match_http_services.dart';
import 'package:linkup/data/http_services/user_http_services/user_http_services.dart';
import 'package:linkup/data/isar_classes/chats_table.dart';
import 'package:linkup/data/models/chat_models/message_model.dart';
import 'package:linkup/data/models/chats_connection_model.dart';
import 'package:linkup/data/models/live_chat_data_model.dart';
import 'package:linkup/data/models/matches_connection_model.dart';
import 'package:linkup/data/websocket_services/chat_socket_services/chat_socket_service.dart';
import 'package:linkup/data/websocket_services/connections_socket_services/connections_socket_services.dart';
import 'package:meta/meta.dart';

part 'connections_event.dart';
part 'connections_state.dart';

class ConnectionsBloc extends Bloc<ConnectionsEvent, ConnectionsState> {
  StreamSubscription<String>? _chatSocketSubscription;
  StreamSubscription<String>? _connectionsSocketSubscription;

  final Map<int, Timer> _typingTimers = {};
  final Isar isar;

  final String _logTag = "ConnectionsBloc";

  void _socketInit() {
    _chatSocketSubscription?.cancel();
    _chatSocketSubscription = ChatSocketServices.chatsMessageStream.listen((raw) {
      final currentState = state;
      if (currentState is! ConnectionsLoaded) return;

      final data = jsonDecode(raw);

      if (data["type"] == "chats") {
        if (data["chats_type"] == "message") {
          final recievedMessage = Message.fromJson(data);

          if (_typingTimers.containsKey(recievedMessage.chatRoomId)) {
            _typingTimers[recievedMessage.chatRoomId]?.cancel();
            _typingTimers.remove(recievedMessage.chatRoomId);
          }

          add(
            ReloadChatConnectionsEvent(
              liveChatData: LiveChatDataModel(
                from_: recievedMessage.from_,
                chatRoomId: recievedMessage.chatRoomId,
                message: recievedMessage.message,
                unseenCounterIncBy: 1,
                messageType: recievedMessage.media != null ? MessageType.image : MessageType.text,
                changeOrder: true,
              ),
            ),
          );
        }
        if (data["chats_type"] == "typing") {
          final recievedMessage = Message.fromJson(data);
          final currentLastMessage = currentState.chats.firstWhere((chat) => chat.chatRoomId == recievedMessage.chatRoomId);

          add(
            ReloadChatConnectionsEvent(
              liveChatData: LiveChatDataModel(
                from_: recievedMessage.from_,
                chatRoomId: recievedMessage.chatRoomId,
                message: recievedMessage.message,
                unseenCounterIncBy: 0,
                messageType: MessageType.text,
              ),
            ),
          );

          _typingTimers[recievedMessage.chatRoomId]?.cancel();

          _typingTimers[recievedMessage.chatRoomId] = Timer(Duration(seconds: 3), () {
            add(
              ReloadChatConnectionsEvent(
                liveChatData: LiveChatDataModel(
                  from_: recievedMessage.from_,
                  chatRoomId: recievedMessage.chatRoomId,
                  message: currentLastMessage.message ?? "",
                  unseenCounterIncBy: 0,
                  messageType: currentLastMessage.messageType,
                ),
              ),
            );
            _typingTimers.remove(recievedMessage.chatRoomId);
          });
        }
      }
    });

    _connectionsSocketSubscription?.cancel();
    _connectionsSocketSubscription = ConnectionsSocketService.connectionsMessageStream.listen((raw) {
      final currentState = state;
      if (currentState is! ConnectionsLoaded) return;
      final data = jsonDecode(raw);

      log("Data recieved $data", name: _logTag);

      if (data["type"] == "connections-reload") {
        add(LoadConnectionsEvent(showLoading: false));
      }
    });
  }

  ConnectionsBloc({required this.isar}) : super(ConnectionsInitial()) {
    on<LoadConnectionsEvent>((event, emit) async {
      // Show loading only if showLoading is false
      if (event.showLoading != false) {
        emit(ConnectionsLoading());
      }

      try {
        Map<String, dynamic> connections = {};

        log('Loading connections...', name: _logTag);

        try {
          connections = await MatchHttpServices().getConnections();
        } catch (httpError) {
          final List<ChatsTable> cacheChatsTables = await isar.chatsTables.where().findAll();
          connections['chats'] = cacheChatsTables.map((chatTable) => chatTable.toChatsConnectionModel()).toList();
          connections['matches'] = List<MatchesConnectionModel>.from([]);
        }

        await isar.writeTxn(() async {
          await isar.chatsTables.clear();
          for (ChatsConnectionModel chat in connections['chats'] as List<ChatsConnectionModel>) {
            await isar.chatsTables.put(ChatsTable.fromChat(chat));
          }
        });

        _socketInit();

        emit(ConnectionsLoaded(matches: connections['matches'] as List<MatchesConnectionModel>, chats: connections['chats'] as List<ChatsConnectionModel>));
      } on Exception catch (e, stackTrace) {
        log('Error loading connections: $e', stackTrace: stackTrace, name: _logTag);
        emit(ConnectionsError());
      }
    });

    on<ReportUserEvent>((event, emit) async {
      try {
        await UserHttpServices().reportUser(userId: event.userIdToReport, reason: event.reason);
        log("User reported successfully", name: _logTag);
      } catch (e) {
        log("Error reporting user: $e", name: _logTag);
        // You could emit a specific error state here if you wanted to show a snackbar from the bloc listener
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

          updatedChats[index] = oldChat.copyWith(message: liveChatData.message, unseenCounter: oldChat.unseenCounter + liveChatData.unseenCounterIncBy, messageType: liveChatData.messageType);

          if (event.liveChatData!.changeOrder) {
            final latestChat = updatedChats.removeAt(index);
            updatedChats.insert(0, latestChat);
          }

          emit(currentState.copyWith(chats: updatedChats));
        }
      }
    });

    on<MarkMessagesSeenEvent>((event, emit) {
      final currentState = state;
      if (currentState is! ConnectionsLoaded) {
        return;
      }

      final List<ChatsConnectionModel> updatedChats = List.from(currentState.chats);
      final index = updatedChats.indexWhere((chat) => chat.chatRoomId == event.chatRoomId);

      if (index != -1) {
        final oldChat = updatedChats[index];
        updatedChats[index] = oldChat.copyWith(unseenCounter: event.decrementCounterTo);
        emit(currentState.copyWith(chats: updatedChats));
      }
    });

    on<BlockUserEvent>((event, emit) async {
      final currentState = state;
      // Optimistic Update: Immediately remove from UI
      if (currentState is ConnectionsLoaded) {
        final updatedChats = List<ChatsConnectionModel>.from(currentState.chats);
        final updatedMatches = List<MatchesConnectionModel>.from(currentState.matches);

        // Remove from chats if chatRoomId matches OR if the user is the participant
        // (Assuming you have access to participant ID in ChatsConnectionModel, otherwise use chatRoomId)
        if (event.chatRoomId != null) {
          updatedChats.removeWhere((chat) => chat.chatRoomId == event.chatRoomId);
        }

        // Remove from matches
        updatedMatches.removeWhere((match) => match.id == event.userIdToBlock);
        emit(currentState.copyWith(chats: updatedChats, matches: updatedMatches));
      }

      try {
        // Call API
        await UserHttpServices().blockUser(userId: event.userIdToBlock);

        // Optionally reload fresh data from server to ensure sync
        // add(LoadConnectionsEvent(showLoading: false));
      } catch (e) {
        log("Error blocking user: $e", name: _logTag);
        // Ideally, revert state or show error toast here
        // For now, we force a reload to get back strictly correct data
        add(LoadConnectionsEvent(showLoading: false));
      }
    });
  }

  @override
  Future<void> close() {
    _chatSocketSubscription?.cancel();
    return super.close();
  }
}
