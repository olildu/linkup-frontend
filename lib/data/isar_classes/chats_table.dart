import 'dart:convert';
import 'package:isar/isar.dart';
import 'package:linkup/data/models/chats_connection_model.dart';

part 'chats_table.g.dart';

@collection
class ChatsTable {
  Id id = Isar.autoIncrement;

  late int chatID;
  late String username;
  late String profilePictureMetaDataJson; 
  late int chatRoomId;
  late int unseenCounter;
  late String? message;

  ChatsTable();

  ChatsTable.fromChat(ChatsConnectionModel chatsConnectionModel) {
    chatID = chatsConnectionModel.id;
    username = chatsConnectionModel.username;
    profilePictureMetaDataJson = jsonEncode(chatsConnectionModel.profilePictureMetaData);
    chatRoomId = chatsConnectionModel.chatRoomId;
    unseenCounter = chatsConnectionModel.unseenCounter;
    message = chatsConnectionModel.message;
  }

  ChatsConnectionModel toChatsConnectionModel() {
    return ChatsConnectionModel(
      id: chatID,
      username: username,
      profilePictureMetaData: jsonDecode(profilePictureMetaDataJson),
      chatRoomId: chatRoomId,
      unseenCounter: unseenCounter,
      message: message,
    );
  }
}
