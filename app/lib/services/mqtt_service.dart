import 'dart:async';
import 'dart:convert';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

/// Lightweight standard telemetry (MQTT): subscribes to the mat's live frames and the bridge's health topic
/// on the laptop broker (same Wi-Fi / hotspot as the phone). See docs/mqtt-contract.md.
class MqttService {
  MqttServerClient? _client;
  StreamSubscription? _sub;
  final _frames = StreamController<Map<String, dynamic>>.broadcast();
  final _status = StreamController<Map<String, dynamic>>.broadcast();
  final _connection = StreamController<bool>.broadcast();
  int rejected = 0;

  Stream<Map<String, dynamic>> get frames => _frames.stream;
  Stream<Map<String, dynamic>> get status => _status.stream;
  Stream<bool> get connection => _connection.stream;
  bool get isConnected => _client?.connectionStatus?.state == MqttConnectionState.connected;

  Future<bool> connect({required String host, required String device, int port = 1883, String root = 'qadam'}) async {
    await disconnect();
    final client = MqttServerClient.withPort(host, 'qadam-app-${DateTime.now().millisecondsSinceEpoch}', port);
    client.keepAlivePeriod = 20;
    client.connectTimeoutPeriod = 4000;
    client.autoReconnect = true;
    client.resubscribeOnAutoReconnect = true;
    client.logging(on: false);
    client.onConnected = () => _connection.add(true);
    client.onAutoReconnected = () => _connection.add(true);
    client.onDisconnected = () => _connection.add(false);
    client.onAutoReconnect = () => _connection.add(false);
    client.connectionMessage = MqttConnectMessage().startClean();
    try {
      await client.connect();
    } catch (_) {
      client.disconnect();
      _connection.add(false);
      return false;
    }
    if (client.connectionStatus?.state != MqttConnectionState.connected) {
      _connection.add(false);
      return false;
    }
    final live = '$root/$device/live';
    final health = '$root/$device/status';
    client.subscribe(live, MqttQos.atLeastOnce);
    client.subscribe(health, MqttQos.atLeastOnce);
    _sub = client.updates?.listen((events) {
      for (final e in events) {
        final msg = e.payload;
        if (msg is! MqttPublishMessage) continue;
        Map<String, dynamic>? data;
        try {
          final decoded = jsonDecode(utf8.decode(msg.payload.message.toList()));
          if (decoded is Map<String, dynamic>) data = decoded;
        } catch (_) {
          data = null;
        }
        if (data == null) {
          rejected++; // malformed frame: counted, never displayed
          continue;
        }
        if (msg.header?.retain == true) data['_retained'] = true;
        if (e.topic == live) {
          _frames.add(data);
        } else if (e.topic == health) {
          _status.add(data);
        }
      }
    });
    _client = client;
    _connection.add(true);
    return true;
  }

  Future<void> disconnect() async {
    await _sub?.cancel();
    _sub = null;
    _client?.autoReconnect = false;
    _client?.disconnect();
    _client = null;
  }
}
