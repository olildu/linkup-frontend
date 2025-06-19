class LiveChatDataModel {
  final int from_;
  final int chatRoomId;
  final String? message;

  LiveChatDataModel({required this.from_, required this.chatRoomId, this.message});

  factory LiveChatDataModel.fromJson(Map<String, dynamic> json) {
    return LiveChatDataModel(from_: json['from_'] as int, chatRoomId: json['chatRoomId'] as int, message: json['message'] as String?);
  }

  Map<String, dynamic> toJson() {
    return {'from_': from_, 'chatRoomId': chatRoomId, 'message': message};
  }
}
