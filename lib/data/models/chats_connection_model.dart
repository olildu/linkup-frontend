class ChatsConnectionModel {
  final int id;
  final String username;
  final String profilePicture;
  final int chatRoomId;
  final int unseenCounter;
  final String? message;

  ChatsConnectionModel({
    required this.id,
    required this.username,
    required this.profilePicture,
    required this.chatRoomId,
    required this.unseenCounter,
    this.message,
  });

  factory ChatsConnectionModel.fromJson(Map<String, dynamic> json) {
    return ChatsConnectionModel(
      id: json['id'],
      username: json['username'],
      profilePicture: json['profile_picture'],
      chatRoomId: json['chat_room_id'],
      unseenCounter: json['unseen_counter'],
      message: json['last_message'],
    );
  }

  ChatsConnectionModel copyWith({int? id, String? username, String? profilePicture, int? chatRoomId, int? unseenCounter, String? message}) {
    return ChatsConnectionModel(
      id: id ?? this.id,
      username: username ?? this.username,
      profilePicture: profilePicture ?? this.profilePicture,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      unseenCounter: unseenCounter ?? this.unseenCounter,
      message: message ?? this.message,
    );
  }
}
