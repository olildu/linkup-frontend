import 'dart:convert';

import 'package:isar/isar.dart';
import 'package:linkup/data/models/chat_models/message_model.dart';

part 'media_table.g.dart';

@embedded
class MediaTable {
  late String fileKey;

  @enumerated
  late MessageType mediaType;
  late String blurhashText;
  late String metadataJson;

  @ignore
  Map<String, dynamic> get metadata => jsonDecode(metadataJson);

  set metadata(Map<String, dynamic> value) => metadataJson = jsonEncode(value);
}
