import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothDeviceModel {
  final String id;
  final String name;
  final bool isConnected;
  final int? signalStrength;

  BluetoothDeviceModel({
    required this.id,
    required this.name,
    this.isConnected = false,
    this.signalStrength,
  });

  factory BluetoothDeviceModel.fromScanResult(ScanResult result) {
    return BluetoothDeviceModel(
      id: result.device.remoteId.str,
      name: result.device.platformName ?? 'Unknown Device',
      signalStrength: result.rssi,
    );
  }
}