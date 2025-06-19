import 'package:linkup/data/models/chat_models/media_message_data_model.dart';

enum MessageType { text, voice, image }

class Message {
  final int? id;
  final String message;

  final int to;
  final int from_;

  final int chatRoomId;
  final bool isSeen;

  final DateTime timestamp;
  final MediaMessageData? media;

  Message({
    required this.message,
    required this.to,
    required this.timestamp,
    required this.from_,
    required this.chatRoomId,
    this.id = -1,
    this.isSeen = false,
    this.media,
  });

  Message copyWith({int? id, String? message, int? to, int? from_, DateTime? timestamp, int? chatRoomId, bool? isSeen, MediaMessageData? media}) {
    return Message(
      id: id ?? this.id,
      message: message ?? this.message,
      to: to ?? this.to,
      from_: from_ ?? this.from_,
      timestamp: timestamp ?? this.timestamp,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      isSeen: isSeen ?? this.isSeen,
      media: media ?? this.media,
    );
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: (json['message_id'] ?? -1) as int,
      message: json['message'] as String,
      to: json['to'] as int,
      from_: json['from_'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      chatRoomId: json['chat_room_id'] as int,
      isSeen: (json['is_seen'] ?? false) as bool,
      media: json['media'] != null ? MediaMessageData.fromJson(json['media'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final data = {"type": "chats", "chats_type": "message", 'message': message, 'to': to, 'from_': from_, 'chat_room_id': chatRoomId};
    if (media != null) {
      data['media'] = media!.toJson();
    }
    return data;
  }
}
