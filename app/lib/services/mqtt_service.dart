import 'dart:async';
import 'dart:convert';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

/// Subscribes to the mat topic on the laptop's Mosquitto broker (same Wi-Fi / hotspot as the phone).
class MqttService {
  MqttServerClient? _client;
  final _messages = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messages => _messages.stream;
  bool get isConnected => _client?.connectionStatus?.state == MqttConnectionState.connected;

  Future<bool> connect({required String host, int port = 1883, String topic = 'qadam/mat01/live'}) async {
    disconnect();
    final client = MqttServerClient(host, 'qadam-app-${DateTime.now().millisecondsSinceEpoch}');
    client.port = port;
    client.keepAlivePeriod = 20;
    client.autoReconnect = true;
    client.logging(on: false);
    client.connectionMessage = MqttConnectMessage().startClean();
    try {
      await client.connect();
    } catch (_) {
      client.disconnect();
      return false;
    }
    if (client.connectionStatus?.state != MqttConnectionState.connected) return false;

    client.subscribe(topic, MqttQos.atLeastOnce);
    client.updates?.listen((events) {
      for (final e in events) {
        final msg = e.payload as MqttPublishMessage;
        final text = MqttPublishPayload.bytesToStringAsString(msg.payload.message);
        try {
          final data = jsonDecode(text);
          if (data is Map<String, dynamic>) _messages.add(data);
        } catch (_) {/* ignore non-JSON */}
      }
    });
    _client = client;
    return true;
  }

  void disconnect() {
    _client?.disconnect();
    _client = null;
  }
}
