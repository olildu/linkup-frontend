import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:linkup/data/websocket_services/base_socket_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;

import '../../../presentation/constants/global_constants.dart';

class ConnectionsSocketService extends BaseSocketService {
  ConnectionsSocketService() : super(uri: Uri.parse("$WS_BASE_URL/connections"), logTag: 'ConnectionsSocketService');
  static final ConnectionsSocketService _instance = ConnectionsSocketService();

  factory ConnectionsSocketService.instance() => _instance;

  static Stream<String> get connectionsMessageStream => _instance.messageStream;
  static Stream<String?> get connectionsDisconnectStream => _instance.disconnectStream;
}
