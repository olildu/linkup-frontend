import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:linkup/data/clients/custom_http_client.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;

abstract class BaseSocketService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final CustomHttpClient _client = GetIt.instance<CustomHttpClient>();

  WebSocketChannel? _channel;
  String? _authToken;
  final Uri uri;
  final String logTag;

  final Duration reconnectDelay;
  Timer? _reconnectTimer;
  int _reconnectAttemptCount = 0;

  bool _manualDisconnect = false;
  bool _isConnecting = false;
  bool _currentConnectionStatusEmitted = false;

  final StreamController<String> _messageController = StreamController<String>.broadcast();
  final StreamController<String?> _disconnectController = StreamController<String?>.broadcast();
  final StreamController<bool> _connectionStatusController = StreamController<bool>.broadcast();

  Stream<String> get messageStream => _messageController.stream;
  Stream<String?> get disconnectStream => _disconnectController.stream;
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  bool get isConnected => _channel != null && _channel?.closeCode == null && !_isConnecting;

  BaseSocketService({required this.uri, required this.logTag, this.reconnectDelay = const Duration(seconds: 5)});

  void _updateConnectionStatusController() {
    // Only broadcast if change is there
    if (_currentConnectionStatusEmitted != isConnected) {
      _connectionStatusController.add(isConnected);
      _currentConnectionStatusEmitted = isConnected;
    }
  }

  Future<void> connect({bool isRetry = false}) async {
    if (_isConnecting && !isRetry) {
      log("Connection already in progress.", name: logTag);
      return;
    }
    if (isConnected && !isRetry) {
      log("Already connected.", name: logTag);
      return;
    }

    _isConnecting = true;
    if (!isRetry) _manualDisconnect = false;

    _authToken = await _secureStorage.read(key: 'access_token');
    if (_authToken == null) {
      log("No token found. Connection aborted.", name: logTag);
      _disconnectController.add("No token, connection aborted.");
      _isConnecting = false;
      _updateConnectionStatusController();
      return;
    }

    log("Connecting to $uri (Attempt ${_reconnectAttemptCount + 1})", name: logTag);

    try {
      _channel = IOWebSocketChannel.connect(
        uri,
        headers: {'Authorization': 'Bearer $_authToken'},
        pingInterval: const Duration(seconds: 1),
        connectTimeout: const Duration(seconds: 5),
      );

      _channel!.stream.listen(
        (data) {
          _messageController.add(data);
          if (_reconnectAttemptCount > 0) log("Reconnected successfully.", name: logTag);
          _reconnectAttemptCount = 0;
          _updateConnectionStatusController();
        },
        onDone: () {
          _isConnecting = false;
          final code = _channel?.closeCode;
          final reason = _channel?.closeReason;
          log("Connection closed. Code: $code, Reason: $reason", name: logTag);
          _channel = null;
          if (!_manualDisconnect) {
            _disconnectController.add("Closed: Code $code");
            _updateConnectionStatusController();
            _scheduleReconnect();
          } else {
            _disconnectController.add("Disconnected manually");
            _updateConnectionStatusController();
          }
        },
        onError: (error) async {
          _isConnecting = false;
          log("Connection error: $error", name: logTag);
          _channel = null;
          if (!_manualDisconnect) {
            _disconnectController.add("Error: $error");
            if (error.contains('401')) {
              await _client.refreshToken();
              _scheduleReconnect();
            } else {
              _scheduleReconnect();
            }
          }
          _updateConnectionStatusController();
        },
        cancelOnError: true,
      );

      _isConnecting = false;
      log("Connected successfully.", name: logTag);
    } catch (e) {
      _isConnecting = false;
      log("Failed to connect: $e", name: logTag);
      _channel = null;
      if (!_manualDisconnect) {
        _disconnectController.add("Connection failed: $e");
        _scheduleReconnect();
      }
      _updateConnectionStatusController();
    }
  }

  void _scheduleReconnect() {
    if (_manualDisconnect || (_reconnectTimer?.isActive ?? false)) return;

    _reconnectAttemptCount++;
    log("Scheduling reconnect in ${reconnectDelay.inSeconds}s (Attempt $_reconnectAttemptCount)...", name: logTag);

    _reconnectTimer = Timer(reconnectDelay, () => connect(isRetry: true));
  }

  void sendMessage(Map<String, dynamic> message) {
    if (!isConnected) {
      log("Not connected. Message not sent.", name: logTag);
      return;
    }
    try {
      _channel!.sink.add(jsonEncode(message));
    } catch (e) {
      log("Send error: $e", name: logTag);
      _channel = null;
      _isConnecting = false;
      if (!_manualDisconnect) {
        _disconnectController.add("Send failed: $e");
        _scheduleReconnect();

        _updateConnectionStatusController();
      }
    }
  }

  void disconnect() {
    _manualDisconnect = true;
    _reconnectTimer?.cancel();
    _reconnectAttemptCount = 0;

    _channel?.sink.close(status.normalClosure);
    _channel = null;
    _isConnecting = false;

    log("Disconnected manually.", name: logTag);
    _disconnectController.add("Manually disconnected");
    _updateConnectionStatusController();
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _disconnectController.close();
  }
}
