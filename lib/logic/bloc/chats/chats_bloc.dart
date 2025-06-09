import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:linkup/data/http_services/chat_http_services/chat_http_services.dart';
import 'package:linkup/data/models/chat_models/message_model.dart';
import 'package:linkup/data/web_socket_services/chat_socket_services/chat_socket_service.dart';
import 'package:meta/meta.dart';

part 'chats_event.dart';
part 'chats_state.dart';

class ChatsBloc extends Bloc<ChatsEvent, ChatsState> {
  final int currentChatUserId;
  final int currentUserId;
  final int chatRoomId;

  StreamSubscription<String>? _socketSubscription;
  
  Timer? _typingTimer;
  
  ChatsBloc({
    required this.currentChatUserId,
    required this.currentUserId,
    required this.chatRoomId,
  }) : super(ChatsInitial()) {
    on<StartChatsEvent>((event, emit) async {
      emit(ChatsLoading());

      try {
      _socketSubscription?.cancel();
      _socketSubscription = ChatSocketServices.messageStream.listen((raw) {
        final data = jsonDecode(raw);

        if (data["type"] == "chats") {
          if (data["chats_type"] == "message") {
            add(NewMessageEvent(data));
          } else if (data["chats_type"] == "typing") {
            add(TypingEvent(data));
          } else if (data["chats_type"] == "seen") {
            add(SeenEvent(data));
          }
        }
      });

      final messages = await ChatHttpServices().fetchChatMessages(
        chatRoomId: chatRoomId
      );

      emit(ChatsLoaded(messages: messages));
      } catch (e) {
        log("Error starting chat socket: $e");
        emit(ChatsError());
      }
    });
 
    on<SendMessageEvent>((event, emit) {
      final message = event.message;
      final currentState = state;

      if (currentState is ChatsLoaded) {
        final updatedMessages = List<Message>.from(currentState.messages)..add(message);

        log(message.toJson().toString());

        ChatSocketServices.sendMessage(
          messageBody: message.toJson()
        );

        emit(ChatsLoaded(messages: updatedMessages));
      } else {
        emit(ChatsLoaded(messages: [message]));
      }
    });

    on<NewMessageEvent>((event, emit) {
      final message = Message.fromJson(event.message);
      final currentState = state;

      if (currentState is ChatsLoaded) {
        if (message.to == currentUserId && message.from_ == currentChatUserId) {
          final updatedMessages = List<Message>.from(currentState.messages)..add(message);
          emit(ChatsLoaded(messages: updatedMessages));
        }
    } else {
        emit(ChatsLoaded(messages: [message]));
      }
    });
  
    on<MarkMessageAsSeenEvent>((event, emit) {
      final currentState = state;
      if (currentState is! ChatsLoaded) return;

      final messageIndex = currentState.messages.lastIndexWhere((msg) => msg.id == event.messageId);

      if (messageIndex == -1 || currentState.messages[messageIndex].isSeen) {
        return;
      }

      final messageToUpdate = currentState.messages[messageIndex];
      final updatedMessage = messageToUpdate.copyWith(isSeen: true);

      final updatedMessages = List<Message>.from(currentState.messages);
      updatedMessages[messageIndex] = updatedMessage;

      ChatSocketServices.sendMessage(
        messageBody: {
          "type": "chats",
          "chats_type": "seen",
          "to": currentChatUserId,
          "from_": currentUserId,
          "chat_room_id" : chatRoomId,
          "message_id" : event.messageId
        }
      );

      emit(currentState.copyWith(messages: updatedMessages));
    });

    on<SeenEvent>((event, emit) {
      final currentState = state;
      log("Event ${event.message}");

      log("Seen Event sighted");

      if (event.message["from_"] != currentChatUserId) return;

      if (currentState is ChatsLoaded) {
        emit(currentState.copyWith(
          otherUserSeenMsg: true,
        ));
      }
    });


    on<TypingEvent>((event, emit) {
      final currentState = state;
      final message = Message.fromJson(event.message);

      if (message.from_ != currentChatUserId) return;

      if (currentState is ChatsLoaded) {
        emit(currentState.copyWith(
          isTyping: true,
          typingUserId: message.from_,
        ));

        _typingTimer?.cancel();
        _typingTimer = Timer(const Duration(seconds: 3), () {
          add(TypingTimeoutEvent(userId: message.from_));
        });
      }
    });

    on<TypingTimeoutEvent>((event, emit) {
      final currentState = state;
      if (currentState is ChatsLoaded && currentState.typingUserId == event.userId) {
        emit(currentState.copyWith(
          isTyping: false,
          typingUserId: null,
        ));
      }
    });

    on<SendTypingEvent>((event, emit) {
      final currentState = state;

      if (currentState is ChatsLoaded) {
        ChatSocketServices.sendMessage(
          messageBody: {
            "type": "chats",
            "chats_type": "typing",
            "to": event.currentChatUserId,
            "from_": currentUserId,
            "chat_room_id" : chatRoomId,
          }
        );
      }
    });
  }

  @override
  Future<void> close() {
    _socketSubscription?.cancel();
    return super.close();
  }
}
