import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../utils/constants.dart';

class MyBluetoothService {  // Changed from BluetoothService to MyBluetoothService
  static final MyBluetoothService _instance = MyBluetoothService._internal();
  factory MyBluetoothService() => _instance;
  MyBluetoothService._internal();

  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? messageCharacteristic;

  // Discover nearby devices
  Stream<List<ScanResult>> discoverDevices() {
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    return FlutterBluePlus.scanResults;
  }

  // Connect to a device
  Future<void> connectToDevice(BluetoothDevice device) async {
    await device.connect(autoConnect: false);
    connectedDevice = device;

    // Discover services - now correctly references the package's BluetoothService
    List<BluetoothService> services = await device.discoverServices();

    for (BluetoothService service in services) {  // Explicit type here
      if (service.serviceUuid.toString() == AppConstants.chatServiceUuid) {  // Changed to serviceUuid
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          if (characteristic.characteristicUuid.toString() == AppConstants.messageCharacteristicUuid) {
            messageCharacteristic = characteristic;
            await characteristic.setNotifyValue(true);
          }
        }
      }
    }
  }

  // Send message
  Future<void> sendMessage(String message) async {
    if (messageCharacteristic == null) return;
    await messageCharacteristic!.write(message.codeUnits);
  }

  // Receive messages
  Stream<String> receiveMessages() {
    if (messageCharacteristic == null) return const Stream.empty();
    return messageCharacteristic!.onValueReceived.map((value) => String.fromCharCodes(value));
  }

  // Disconnect
  Future<void> disconnect() async {
    if (connectedDevice == null) return;
    await connectedDevice!.disconnect();
    connectedDevice = null;
    messageCharacteristic = null;
  }
}