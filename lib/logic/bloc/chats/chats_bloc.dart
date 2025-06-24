import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:isar/isar.dart';
import 'package:linkup/data/http_services/chat_http_services/chat_http_services.dart';
import 'package:linkup/data/http_services/common_http_services/common_http_services.dart';
import 'package:linkup/data/isar_classes/message_table.dart';
import 'package:linkup/data/models/chat_models/media_message_data_model.dart';
import 'package:linkup/data/models/chat_models/message_model.dart';
import 'package:linkup/data/websocket_services/chat_socket_services/chat_socket_service.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

part 'chats_event.dart';
part 'chats_state.dart';

class ChatsBloc extends Bloc<ChatsEvent, ChatsState> {
  final int currentChatUserId;
  final int currentUserId;
  final int chatRoomId;
  final Isar isar;

  StreamSubscription<String>? _socketSubscription;
  Timer? _typingKillTimer;
  Timer? _typingTimer;
  bool _typingTimerActive = false;

  ChatsBloc({required this.currentChatUserId, required this.currentUserId, required this.chatRoomId, required this.isar}) : super(ChatsInitial()) {
    on<StartChatsEvent>(_onStartChats);
    on<SendMessageEvent>(_onSendMessage);
    on<NewMessageEvent>(_onNewMessage);
    on<MarkMessageAsSeenEvent>(_onMarkSeen);
    on<SeenEvent>(_onSeenEvent);
    on<TypingEvent>(_onTypingEvent);
    on<TypingTimeoutEvent>(_onTypingTimeout);
    on<SendTypingEvent>(_onSendTyping);
    on<UploadMediaEvent>(_onUploadMedia);
    on<PaginateAddMessagesEvent>(_onPaginateAddMessagesEvent);
    on<_ClearSocketDisconnectedFlagEvent>(_onClearSocketDisconnectedFlagEvent);
  }

  Future<void> _onStartChats(StartChatsEvent event, Emitter<ChatsState> emit) async {
    emit(ChatsLoading());
    try {
      _socketSubscription?.cancel();
      _socketSubscription = ChatSocketServices.messageStream.listen((raw) {
        final data = jsonDecode(raw);
        if (data["type"] == "chats") {
          switch (data["chats_type"]) {
            case "message":
              add(NewMessageEvent(data));
              break;
            case "typing":
              add(TypingEvent(data));
              break;
            case "seen":
              add(SeenEvent(data));
              break;
          }
        }
      });

      late List<Message> messages = [];
      try {
        messages = await ChatHttpServices().fetchChatMessages(chatRoomId: chatRoomId);
      } catch (httpError) {
        log("[ChatsBloc] No internet reffering to cache");
        messages = (await isar.messageTables.filter().chatRoomIdEqualTo(chatRoomId).findAll()).map((e) => e.toMessage()).toList();

        // TODO
      }

      await isar.writeTxn(() async {
        List first20Messages = (messages.sublist(
          0,
          messages.length >= 20 ? 20 : messages.length,
        )); // We are interested to store only first 20 messages
        await isar.messageTables.filter().chatRoomIdEqualTo(chatRoomId).deleteAll(); // Delete all messages from the current ChatRoomID

        for (Message message in first20Messages) {
          await isar.messageTables.put(MessageTable.fromMessage(message));
        }
      });

      log("[ChatsBloc] Chat socket initialized");
      emit(ChatsLoaded(messages: messages, isSocketConnected: true));
    } catch (e, stackTrace) {
      log("[ChatsBloc] StartChatsEvent error", error: e, stackTrace: stackTrace);
      emit(ChatsError());
    }
  }

  Future<void> _onSendMessage(SendMessageEvent event, Emitter<ChatsState> emit) async {
    try {
      final message = event.message;
      final currentState = state;

      if (currentState is ChatsLoaded) {
        if (ChatSocketServices.isConnected) {
          final updatedMessages = List<Message>.from(currentState.messages)..add(message); // Add to messageList
          ChatSocketServices.sendMessage(messageBody: message.toJson()); // Send to socket

          await isar.writeTxn(() async {
            final tableMessageCount = await isar.messageTables.filter().chatRoomIdEqualTo(chatRoomId).count(); // Fetch count
            if (tableMessageCount >= 20) {
              // If tableMessageCount
              // Delete first message which is filtered using timestamp
              final lastMessage = await isar.messageTables.filter().chatRoomIdEqualTo(chatRoomId).sortByTimestamp().findFirst();
              if (lastMessage != null) {
                // Null check
                isar.messageTables.delete(lastMessage.id);
              }
            }

            isar.messageTables.put(MessageTable.fromMessage(message)); // Add new message to cache
          });

          emit(currentState.copyWith(messages: updatedMessages, otherUserSeenMsg: false)); // Emit new state
        } else {
          final beforeInsertionMessageList = currentState.messages;
          final updatedMessages = List<Message>.from(currentState.messages)..add(message);
          emit(currentState.copyWith(messages: updatedMessages, otherUserSeenMsg: false));

          await Future.delayed(Duration(seconds: 1));
          add(_ClearSocketDisconnectedFlagEvent(message: message, beforeInsertionMessageList: beforeInsertionMessageList));
        }
      } else {
        emit(ChatsLoaded(messages: [message]));
      }
    } catch (e, stackTrace) {
      log("[ChatsBloc] SendMessageEvent error", error: e, stackTrace: stackTrace);
    }
  }

  void _onNewMessage(NewMessageEvent event, Emitter<ChatsState> emit) {
    try {
      final message = Message.fromJson(event.message);
      final currentState = state;

      if (currentState is ChatsLoaded) {
        if (message.to == currentUserId && message.from_ == currentChatUserId) {
          final updatedMessages = List<Message>.from(currentState.messages)..add(message);
          log("[ChatsBloc] Message received");
          emit(currentState.copyWith(messages: updatedMessages, isTyping: false));
        }
      } else {
        emit(ChatsLoaded(messages: [message]));
      }
    } catch (e, stackTrace) {
      log("[ChatsBloc] NewMessageEvent error", error: e, stackTrace: stackTrace);
    }
  }

  void _onMarkSeen(MarkMessageAsSeenEvent event, Emitter<ChatsState> emit) {
    try {
      final currentState = state;
      if (currentState is! ChatsLoaded) return;

      final index = currentState.messages.lastIndexWhere((msg) => msg.id == event.messageId);
      if (index == -1 || currentState.messages[index].isSeen) return;

      final updatedMessage = currentState.messages[index].copyWith(isSeen: true);
      final updatedMessages = List<Message>.from(currentState.messages);
      updatedMessages[index] = updatedMessage;

      ChatSocketServices.sendMessage(
        messageBody: {
          "type": "chats",
          "chats_type": "seen",
          "to": currentChatUserId,
          "from_": currentUserId,
          "chat_room_id": chatRoomId,
          "message_id": event.messageId,
        },
      );

      log("[ChatsBloc] Message marked as seen: ${event.messageId}");
      emit(currentState.copyWith(messages: updatedMessages));
    } catch (e, stackTrace) {
      log("[ChatsBloc] MarkMessageAsSeenEvent error", error: e, stackTrace: stackTrace);
    }
  }

  Future<void> _onSeenEvent(SeenEvent event, Emitter<ChatsState> emit) async {
    try {
      final currentState = state;
      if (event.message["from_"] != currentChatUserId) return;

      if (currentState is ChatsLoaded) {
        log("[ChatsBloc] Seen event received");

        await isar.writeTxn(() async {
          final message = await isar.messageTables.filter().messageIDEqualTo(event.message["message_id"]).findFirst();

          if (message != null) {
            message.isSeen = true;
            await isar.messageTables.put(message);
          }
        });

        emit(currentState.copyWith(otherUserSeenMsg: true));
      }
    } catch (e, stackTrace) {
      log("[ChatsBloc] SeenEvent error", error: e, stackTrace: stackTrace);
    }
  }

  void _onTypingEvent(TypingEvent event, Emitter<ChatsState> emit) {
    try {
      final currentState = state;
      final message = Message.fromJson(event.message);

      if (message.from_ != currentChatUserId) return;

      if (currentState is ChatsLoaded) {
        emit(currentState.copyWith(isTyping: true, typingUserId: message.from_));
        _typingKillTimer?.cancel();
        _typingKillTimer = Timer(const Duration(seconds: 3), () {
          add(TypingTimeoutEvent(userId: message.from_));
        });

        log("[ChatsBloc] Typing event from ${message.from_}");
      }
    } catch (e, stackTrace) {
      log("[ChatsBloc] TypingEvent error", error: e, stackTrace: stackTrace);
    }
  }

  void _onTypingTimeout(TypingTimeoutEvent event, Emitter<ChatsState> emit) {
    try {
      final currentState = state;
      if (currentState is ChatsLoaded && currentState.typingUserId == event.userId) {
        emit(currentState.copyWith(isTyping: false, typingUserId: null));
      }
    } catch (e, stackTrace) {
      log("[ChatsBloc] TypingTimeoutEvent error", error: e, stackTrace: stackTrace);
    }
  }

  void _onSendTyping(SendTypingEvent event, Emitter<ChatsState> emit) {
    try {
      final currentState = state;
      if (currentState is ChatsLoaded && !_typingTimerActive) {
        ChatSocketServices.sendMessage(
          messageBody: {"type": "chats", "chats_type": "typing", "to": event.currentChatUserId, "from_": currentUserId, "chat_room_id": chatRoomId},
        );

        _typingTimerActive = true;
        _typingTimer?.cancel();
        _typingTimer = Timer(const Duration(milliseconds: 1500), () {
          _typingTimerActive = false;
        });

        log("[ChatsBloc] Typing event sent");
      }
    } catch (e, stackTrace) {
      log("[ChatsBloc] SendTypingEvent error", error: e, stackTrace: stackTrace);
    }
  }

  Future<void> _onUploadMedia(UploadMediaEvent event, Emitter<ChatsState> emit) async {
    try {
      final currentState = state;
      if (state is! ChatsLoaded) return;

      final metadata = await CommonHttpServices().uploadMedia(file: event.file, mediaType: event.mediaType);
      log("[ChatsBloc] Media uploaded");

      final Message message = Message(
        id: Uuid().v4(),
        message: "",
        to: currentChatUserId,
        timestamp: DateTime.now(),
        from_: currentUserId,
        chatRoomId: chatRoomId,
        media: MediaMessageData(fileKey: metadata["file_key"], mediaType: MessageType.image, blurhashText: "", metadata: metadata["metadata"]),
      );

      await Future.delayed(Duration(milliseconds: 500));

      add(SendMessageEvent(message: message));
      emit(currentState);
    } catch (e, stackTrace) {
      log("[ChatsBloc] UploadMediaEvent error", error: e, stackTrace: stackTrace);
      emit(ChatsError());
    }
  }

  Future<void> _onPaginateAddMessagesEvent(PaginateAddMessagesEvent event, Emitter<ChatsState> emit) async {
    final currentState = state;
    if (currentState is! ChatsLoaded) return;

    // Fetch older messages using the last known message ID
    final olderMessages = await ChatHttpServices().fetchPaginatedChatMessages(
      chatRoomId: chatRoomId,
      lastMessageId: event.lastMessageID,
      lastMessageTimeStamp: event.lastMessageTimeStamp,
    );

    final currentMessages = currentState.messages;

    for (var x in olderMessages) {
      log("Fetched older message ID: ${x.message}, ${x.id}");
    }

    // Prepend older messages to current messages
    final updatedMessages = [...olderMessages, ...currentMessages];

    emit(currentState.copyWith(messages: updatedMessages));
  }

  Future<void> _onClearSocketDisconnectedFlagEvent(_ClearSocketDisconnectedFlagEvent event, Emitter<ChatsState> emit) async {
    final currentState = state;
    if (currentState is! ChatsLoaded) return;

    emit(currentState.copyWith(messages: event.beforeInsertionMessageList, isSocketConnected: false, message: event.message));
  }

  @override
  Future<void> close() {
    _socketSubscription?.cancel();
    _typingTimer?.cancel();
    _typingKillTimer?.cancel();
    return super.close();
  }
}
