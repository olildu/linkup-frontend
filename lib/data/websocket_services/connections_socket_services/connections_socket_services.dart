import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;

import '../../../presentation/constants/global_constants.dart';

class ConnectionsSocketService {
  static final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static WebSocketChannel? _connectionsChannel;
  static String? _authToken;

  static final StreamController<String> _connectionsMessageController = StreamController<String>.broadcast();
  static Stream<String> get connectionsMessageStream => _connectionsMessageController.stream;

  static final StreamController<String?> _connectionsDisconnectController = StreamController<String?>.broadcast();
  static Stream<String?> get connectionsDisconnectStream => _connectionsDisconnectController.stream;

  static Timer? _reconnectTimer;
  static int _reconnectAttemptCount = 0;
  static const Duration _reconnectDelay = Duration(seconds: 5);

  static bool _manualDisconnect = false;
  static bool _isConnecting = false;

  static const String _logTag = "ConnectionsSocketService";

  static bool get isConnected => _connectionsChannel != null && _connectionsChannel?.closeCode == null && !_isConnecting;

  static Future<void> connect({bool isRetry = false}) async {
    if (_isConnecting && !isRetry) {
      log("Connection attempt already in progress.", name: _logTag);
      return;
    }
    if (isConnected && !isRetry) {
      log("Already connected.", name: _logTag);
      return;
    }

    _isConnecting = true;
    if (!isRetry) {
      _manualDisconnect = false;
    }

    _authToken = await _secureStorage.read(key: 'access_token');
    if (_authToken == null) {
      log("No auth token found. Connection aborted.", name: _logTag);
      _connectionsDisconnectController.add("No token, connection aborted.");
      _isConnecting = false;
      return;
    }

    final uri = Uri.parse("$WS_BASE_URL/connections");
    log("Attempting to connect: $uri (Attempt: ${_reconnectAttemptCount + 1})", name: _logTag);

    try {
      _connectionsChannel = IOWebSocketChannel.connect(
        uri,
        headers: {'Authorization': 'Bearer $_authToken'},
        pingInterval: const Duration(seconds: 1),
        connectTimeout: const Duration(seconds: 5),
      );

      _isConnecting = false;
      _connectionsChannel!.stream.listen(
        (data) {
          _connectionsMessageController.add(data);

          if (_reconnectAttemptCount > 0) {
            log("Reconnected successfully.", name: _logTag);
          }
          _reconnectAttemptCount = 0;
        },
        onDone: () {
          _isConnecting = false;
          final closeCode = _connectionsChannel?.closeCode;
          final closeReason = _connectionsChannel?.closeReason;
          log("Closed. Code: $closeCode, Reason: $closeReason, Manual: $_manualDisconnect", name: _logTag);
          _connectionsChannel = null;
          if (!_manualDisconnect) {
            _connectionsDisconnectController.add("Closed (Done): Code $closeCode");
            _scheduleReconnect();
          } else {
            _connectionsDisconnectController.add("Manually disconnected (Done)");
          }
        },
        onError: (error) {
          _isConnecting = false;
          log("Error: $error, Manual: $_manualDisconnect", name: _logTag);
          _connectionsChannel = null;
          if (!_manualDisconnect) {
            _connectionsDisconnectController.add("Error: $error");
            _scheduleReconnect();
          } else {
            _connectionsDisconnectController.add("Error during manual disconnect: $error");
          }
        },
        cancelOnError: true,
      );

      log("Connected and listener active.", name: _logTag);
    } catch (e) {
      _isConnecting = false;
      log("Failed to connect (exception): $e", name: _logTag);
      _connectionsChannel = null;
      if (!_manualDisconnect) {
        _connectionsDisconnectController.add("Connection failed: $e");
        _scheduleReconnect();
      } else {
        _connectionsDisconnectController.add("Connection failed during manual disconnect attempt: $e");
      }
    }
  }

  static void _scheduleReconnect() {
    if (_reconnectTimer != null && _reconnectTimer!.isActive) {
      return;
    }
    if (_manualDisconnect) {
      log("Manual disconnect. No reconnect scheduled.", name: _logTag);
      return;
    }

    _reconnectAttemptCount++;
    log("Scheduling reconnect attempt $_reconnectAttemptCount in ${_reconnectDelay.inSeconds} seconds...", name: _logTag);

    _reconnectTimer = Timer(_reconnectDelay, () {
      log("Retrying connection (attempt $_reconnectAttemptCount)...", name: _logTag);
      connect(isRetry: true);
    });
  }

  static void sendMessage({required Map<String, dynamic> message}) {
    if (!isConnected) {
      log("Not connected. Cannot send message. Channel: $_connectionsChannel, isConnecting: $_isConnecting", name: _logTag);
      return;
    }

    final payload = jsonEncode(message);

    try {
      _connectionsChannel!.sink.add(payload);
    } catch (e) {
      log("Failed to send message: $e. Disconnecting and trying reconnect.", name: _logTag);
      _connectionsChannel = null;
      _isConnecting = false;
      if (!_manualDisconnect) {
        _connectionsDisconnectController.add("Send failed: $e");
        _scheduleReconnect();
      }
    }
  }

  static void disconnect() { 
    log("Manual disconnect initiated.", name: _logTag);
    _manualDisconnect = true;
    _reconnectTimer?.cancel();
    _reconnectAttemptCount = 0;

    if (_connectionsChannel != null) {
      _connectionsChannel!.sink.close(status.normalClosure);
      _connectionsChannel = null;
      log("Closed by client.", name: _logTag);
    } else {
      log("No active connection to close.", name: _logTag);
    }
    _isConnecting = false;
    _connectionsDisconnectController.add("Manually disconnected by client");
  }

  static void dispose() {
    log("Disposing.", name: _logTag);
    disconnect();
    _connectionsMessageController.close();
    _connectionsDisconnectController.close();
  }
}
