import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../core/constants.dart';

class BleConnectionManager {
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? writeCharacteristic;

  Future<void> connectToDevice(BluetoothDevice device, Function(String) onMessageReceived) async {
    await device.connect(timeout: const Duration(seconds: 10));
    connectedDevice = device;

    final services = await device.discoverServices();
    for (final service in services) {
      for (final characteristic in service.characteristics) {
        if (characteristic.uuid.toString().toLowerCase() == characteristicUUID) {
          writeCharacteristic = characteristic;
          await characteristic.setNotifyValue(true);
          characteristic.onValueReceived.listen((value) {
            final message = utf8.decode(value);
            onMessageReceived(message);
          });
          return;
        }
      }
    }
  }

  Future<void> sendMessage(String message) async {
    if (writeCharacteristic == null) return;
    final data = utf8.encode(message);
    await writeCharacteristic!.write(data, withoutResponse: true);
  }

  void disconnect() {
    connectedDevice?.disconnect();
  }
}
