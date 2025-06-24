part of 'chats_bloc.dart';

@immutable
sealed class ChatsState {}

final class ChatsInitial extends ChatsState {}

final class ChatsLoading extends ChatsState {}

final class ChatsLoaded extends ChatsState {
  final List<Message> messages;
  final bool isTyping;
  final bool otherUserSeenMsg;
  final int? typingUserId;
  final bool isSocketConnected;
  final Message? message;

  ChatsLoaded({
    required this.messages,
    this.isTyping = false,
    this.otherUserSeenMsg = false,
    this.typingUserId,
    this.isSocketConnected = false,
    this.message,
  });

  ChatsLoaded copyWith({
    List<Message>? messages,
    bool? isTyping,
    bool? otherUserSeenMsg,
    int? typingUserId,
    bool? isSocketConnected,
    Message? message,
  }) {
    return ChatsLoaded(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
      otherUserSeenMsg: otherUserSeenMsg ?? this.otherUserSeenMsg,
      typingUserId: typingUserId ?? this.typingUserId,
      isSocketConnected: isSocketConnected ?? this.isSocketConnected,
      message: message ?? this.message,
    );
  }
}

final class ChatsError extends ChatsState {}

final class ChatsEmpty extends ChatsState {}
