import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import '../core/constants.dart';

class BleAdvertiser {
  final FlutterBlePeripheral _blePeripheral = FlutterBlePeripheral();

  Future<void> startAdvertising() async {
    final advertiseData = AdvertiseData(
      includeDeviceName: true,
      serviceUuid: serviceUUID,
    );
    await _blePeripheral.start(advertiseData: advertiseData);
  }

  void stopAdvertising() {
    _blePeripheral.stop();
  }
}