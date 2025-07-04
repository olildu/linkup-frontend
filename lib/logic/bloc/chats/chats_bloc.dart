import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:isar/isar.dart';
import 'package:linkup/data/enums/message_type_enum.dart';
import 'package:linkup/data/http_services/chat_http_services/chat_http_services.dart';
import 'package:linkup/data/http_services/common_http_services/common_http_services.dart';
import 'package:linkup/data/isar_classes/message_table.dart';
import 'package:linkup/data/isar_classes/unsent_messages_table.dart';
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

  StreamSubscription<String>? _messageSocketSubscription;
  StreamSubscription<bool>? _statusSubscription;

  Timer? _typingKillTimer;
  Timer? _typingTimer;
  bool _typingTimerActive = false;

  final String _logTag = "ChatsBloc";

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

  // Helper Functions
  void _startSocketListeners() {
    // Message Socket Subscription
    _messageSocketSubscription?.cancel();
    _messageSocketSubscription = ChatSocketServices.messageStream.listen((raw) {
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

    // Connection Status Subscription
    _statusSubscription?.cancel();
    _statusSubscription = ChatSocketServices.connectionStatusStream.listen((connectionStatus) {
      log("Connection status : $connectionStatus", name: _logTag);
      if (connectionStatus == true) {
        add(StartChatsEvent(showLoading: false));
      }
    });
  }

  Future<void> _cacheMessageWithLimit(Message message) async {
    await isar.writeTxn(() async {
      final messageCount = await isar.messageTables.filter().chatRoomIdEqualTo(chatRoomId).count();

      if (messageCount >= 20) {
        final oldestMessage = await isar.messageTables.filter().chatRoomIdEqualTo(chatRoomId).sortByTimestamp().findFirst();

        if (oldestMessage != null) {
          await isar.messageTables.delete(oldestMessage.id);
        }
      }

      await isar.messageTables.put(MessageTable.fromMessage(message));
    });
  }

  // Event Functions
  Future<void> _onStartChats(StartChatsEvent event, Emitter<ChatsState> emit) async {
    if (!event.showLoading) emit(ChatsLoading()); // If showLoading false then don't emit loading
    try {
      late List<Message> messages = [];

      _startSocketListeners();

      try {
        // Try to fetch from internet
        messages = await ChatHttpServices().fetchChatMessages(chatRoomId: chatRoomId);
      } catch (httpError) {
        // Fails then refer to cache for the last 20 messages
        log("No internet reffering to cache", name: _logTag);
        messages = (await isar.messageTables.filter().chatRoomIdEqualTo(chatRoomId).findAll()).map((e) => e.toMessage()).toList();
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

      log("Chat socket initialized", name: _logTag);
      emit(ChatsLoaded(messages: messages, isSocketConnected: ChatSocketServices.isConnected));
    } catch (e, stackTrace) {
      log("StartChatsEvent error", error: e, stackTrace: stackTrace, name: _logTag);
      emit(ChatsError());
    }
  }

  Future<void> _onSendMessage(SendMessageEvent event, Emitter<ChatsState> emit) async {
    try {
      final message = event.message;
      final currentState = state;

      if (currentState is! ChatsLoaded) {
        emit(ChatsLoaded(messages: [message]));
        return;
      }

      final isConnected = ChatSocketServices.isConnected;

      final updatedMessage = isConnected ? message : message.copyWith(isSent: false);
      final updatedMessages = List<Message>.from(currentState.messages)..add(updatedMessage);

      emit(currentState.copyWith(messages: updatedMessages, otherUserSeenMsg: false));

      if (isConnected) {
        ChatSocketServices.sendMessage(messageBody: message.toJson());
      } else {
        add(_ClearSocketDisconnectedFlagEvent(message: updatedMessage));
      }

      await _cacheMessageWithLimit(updatedMessage);
    } catch (e, stackTrace) {
      log("SendMessageEvent error", error: e, stackTrace: stackTrace, name: _logTag);
    }
  }

  void _onNewMessage(NewMessageEvent event, Emitter<ChatsState> emit) {
    try {
      final message = Message.fromJson(event.message);
      final currentState = state;

      if (currentState is ChatsLoaded) {
        if (message.to == currentUserId && message.from_ == currentChatUserId) {
          final updatedMessages = List<Message>.from(currentState.messages)..add(message);
          log("Message received", name: _logTag);
          emit(currentState.copyWith(messages: updatedMessages, isTyping: false));
        }
      } else {
        emit(ChatsLoaded(messages: [message]));
      }
    } catch (e, stackTrace) {
      log("NewMessageEvent error", error: e, stackTrace: stackTrace, name: _logTag);
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

      log("Message marked as seen: ${event.messageId}", name: _logTag);
      emit(currentState.copyWith(messages: updatedMessages));
    } catch (e, stackTrace) {
      log("MarkMessageAsSeenEvent error", error: e, stackTrace: stackTrace, name: _logTag);
    }
  }

  Future<void> _onSeenEvent(SeenEvent event, Emitter<ChatsState> emit) async {
    try {
      final currentState = state;
      if (event.message["from_"] != currentChatUserId) return;

      if (currentState is ChatsLoaded) {
        log("Seen event received", name: _logTag);
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
      log("SeenEvent error", error: e, stackTrace: stackTrace, name: _logTag);
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

        log("Typing event from ${message.from_}", name: _logTag);
      }
    } catch (e, stackTrace) {
      log("TypingEvent error", error: e, stackTrace: stackTrace, name: _logTag);
    }
  }

  void _onTypingTimeout(TypingTimeoutEvent event, Emitter<ChatsState> emit) {
    try {
      final currentState = state;
      if (currentState is ChatsLoaded && currentState.typingUserId == event.userId) {
        emit(currentState.copyWith(isTyping: false, typingUserId: null));
      }
    } catch (e, stackTrace) {
      log("TypingTimeoutEvent error", error: e, stackTrace: stackTrace, name: _logTag);
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

        log("Typing event sent", name: _logTag);
      }
    } catch (e, stackTrace) {
      log("SendTypingEvent error", error: e, stackTrace: stackTrace, name: _logTag);
    }
  }

  Future<void> _onUploadMedia(UploadMediaEvent event, Emitter<ChatsState> emit) async {
    try {
      final currentState = state;
      if (state is! ChatsLoaded) return;

      final metadata = await CommonHttpServices().uploadMedia(file: event.file, mediaType: event.mediaType);
      log("Media uploaded", name: _logTag);
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
      log("UploadMediaEvent error", error: e, stackTrace: stackTrace, name: _logTag);
      emit(ChatsError());
    }
  }

  Future<void> _onPaginateAddMessagesEvent(PaginateAddMessagesEvent event, Emitter<ChatsState> emit) async {
    final currentState = state;
    if (currentState is! ChatsLoaded) return;

    emit(currentState.copyWith(isFetchingPaginatedMessages: true));

    // Fetch older messages using the last known message ID
    final olderMessages = await ChatHttpServices().fetchPaginatedChatMessages(
      chatRoomId: chatRoomId,
      lastMessageId: event.lastMessageID,
      lastMessageTimeStamp: event.lastMessageTimeStamp,
    );

    final currentMessages = currentState.messages;

    for (var x in olderMessages) {
      log("Fetched older message ID: ${x.message}, ${x.id}", name: _logTag);
    }

    // Prepend older messages to current messages
    final updatedMessages = [...olderMessages, ...currentMessages];

    emit(currentState.copyWith(messages: updatedMessages, isFetchingPaginatedMessages: true));
  }

  Future<void> _onClearSocketDisconnectedFlagEvent(_ClearSocketDisconnectedFlagEvent event, Emitter<ChatsState> emit) async {
    final currentState = state;
    if (currentState is! ChatsLoaded) return;

    await isar.writeTxn(() async {
      await isar.unsentMessagesTables.put(UnsentMessagesTable.fromMessage(event.message));
    });
  }

  @override
  Future<void> close() {
    _messageSocketSubscription?.cancel();
    _statusSubscription?.cancel();
    _typingTimer?.cancel();
    _typingKillTimer?.cancel();
    return super.close();
  }
}
