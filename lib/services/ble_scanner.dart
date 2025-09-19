import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../core/constants.dart';

class BleScanner {
  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  void startScan() {
    FlutterBluePlus.startScan(
      withServices: [Guid(serviceUUID)],
      timeout: const Duration(seconds: 15),
    );
  }

  void stopScan() {
    FlutterBluePlus.stopScan();
  }
}