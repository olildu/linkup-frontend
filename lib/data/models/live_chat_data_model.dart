import 'package:linkup/data/models/chat_models/message_model.dart';

class LiveChatDataModel {
  final int from_;
  final int chatRoomId;
  final int unseenCounterIncBy;
  final MessageType messageType;
  final String? message;

  LiveChatDataModel({required this.unseenCounterIncBy, required this.from_, required this.chatRoomId, required this.messageType, this.message});
}
