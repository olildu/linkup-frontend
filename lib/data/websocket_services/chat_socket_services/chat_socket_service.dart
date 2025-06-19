import 'dart:async';
import 'dart:convert';
import 'dart:developer';
// import 'dart:math' as math; // No longer needed for math.pow or math.min

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;

import '../../../presentation/constants/global_constants.dart';

class ChatSocketServices {
  static final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static WebSocketChannel? _channel;
  static String? _currentToken;

  static final StreamController<String> _messageController = StreamController<String>.broadcast();
  static Stream<String> get messageStream => _messageController.stream;

  static final StreamController<String?> _disconnectEventController = StreamController<String?>.broadcast();
  static Stream<String?> get onDisconnectEvent => _disconnectEventController.stream;

  static Timer? _reconnectionTimer;
  static int _reconnectAttempts = 0;
  static const Duration _fixedReconnectDelay = Duration(seconds: 5);

  static bool _isManuallyDisconnected = false;
  static bool _isConnecting = false;

  static bool get isConnected => _channel != null && _channel?.closeCode == null && !_isConnecting;

  static Future<void> connect({bool isRetry = false}) async {
    if (_isConnecting && !isRetry) {
      log("WebSocket connection attempt already in progress.");
      return;
    }
    if (isConnected && !isRetry) {
      log("WebSocket is already connected.");
      return;
    }
    if (_isManuallyDisconnected && !isRetry) {
      log("WebSocket was manually disconnected. Call connect() again if you want to reconnect.");
      return;
    }

    _isConnecting = true;
    if (!isRetry) {
      _isManuallyDisconnected = false;
    }

    _currentToken = await _secureStorage.read(key: 'access_token');
    if (_currentToken == null) {
      log("No token found. WebSocket connection aborted.");
      _disconnectEventController.add("No token, connection aborted.");
      _isConnecting = false;
      return;
    }

    final uri = Uri.parse("$WS_BASE_URL/chat");

    log("Attempting to connect to WebSocket: $uri (Attempt: ${_reconnectAttempts + 1})");

    try {
      _channel = IOWebSocketChannel.connect(
        uri,
        headers: {'Authorization': 'Bearer $_currentToken'},
        pingInterval: const Duration(seconds: 1),
        connectTimeout: const Duration(seconds: 5),
      );

      _isConnecting = false;

      _channel!.stream.listen(
        (data) {
          _messageController.add(data);
          if (_reconnectAttempts > 0) {
            log("WebSocket reconnected successfully.");
          }
          _reconnectAttempts = 0;
        },
        onDone: () {
          _isConnecting = false;
          final closeCode = _channel?.closeCode;
          final closeReason = _channel?.closeReason;
          log("WebSocket connection closed. Code: $closeCode, Reason: $closeReason, Manually disconnected: $_isManuallyDisconnected");
          _channel = null;
          if (!_isManuallyDisconnected) {
            _disconnectEventController.add("Closed (Done): Code $closeCode");
            _scheduleReconnect();
          } else {
            _disconnectEventController.add("Manually disconnected (Done)");
          }
        },
        onError: (error) {
          _isConnecting = false;
          log("WebSocket error: $error. Manually disconnected: $_isManuallyDisconnected");
          _channel = null;
          if (!_isManuallyDisconnected) {
            _disconnectEventController.add("Error: $error");
            _scheduleReconnect();
          } else {
            _disconnectEventController.add("Error during manual disconnect: $error");
          }
        },
        cancelOnError: true,
      );

      log("WebSocket connected to $uri and listener is active.");
    } catch (e) {
      _isConnecting = false;
      log("Failed to connect to WebSocket (exception during connect call): $e");
      _channel = null;
      if (!_isManuallyDisconnected) {
        _disconnectEventController.add("Connection failed: $e");
        _scheduleReconnect();
      } else {
        _disconnectEventController.add("Connection failed during manual disconnect attempt: $e");
      }
    }
  }

  static void _scheduleReconnect() {
    if (_reconnectionTimer != null && _reconnectionTimer!.isActive) {
      return;
    }
    if (_isManuallyDisconnected) {
      log("Manual disconnect in progress. Won't schedule reconnect.");
      return;
    }

    const Duration reconnectDelay = _fixedReconnectDelay;

    _reconnectAttempts++;
    log("Scheduling WebSocket reconnect attempt $_reconnectAttempts in ${reconnectDelay.inSeconds} seconds...");

    _reconnectionTimer = Timer(reconnectDelay, () {
      log("Retrying WebSocket connection (attempt $_reconnectAttempts)...");
      connect(isRetry: true);
    });
  }

  static void sendMessage({required Map messageBody}) {
    if (!isConnected) {
      log("WebSocket not connected. Cannot send message. Current channel: $_channel, isConnecting: $_isConnecting");
      return;
    }

    final payload = jsonEncode(messageBody);

    try {
      _channel!.sink.add(payload);
    } catch (e) {
      log("Failed to send message: $e. Marking as disconnected and attempting reconnect.");
      _channel = null;
      _isConnecting = false;
      if (!_isManuallyDisconnected) {
        _disconnectEventController.add("Send failed: $e");
        _scheduleReconnect();
      }
    }
  }

  static void disconnect() {
    log("Manual WebSocket disconnection initiated.");
    _isManuallyDisconnected = true;
    _reconnectionTimer?.cancel();
    _reconnectAttempts = 0;

    if (_channel != null) {
      _channel!.sink.close(status.goingAway);
      _channel = null;
      log("WebSocket connection closed by client.");
    } else {
      log("No active WebSocket connection to close.");
    }
    _isConnecting = false;
    _disconnectEventController.add("Manually disconnected by client");
  }

  static void dispose() {
    log("Disposing ChatSocketServices.");
    disconnect();
    _messageController.close();
    _disconnectEventController.close();
  }
}
