import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart'; // New import for advertising

// Define a simple message structure for demonstration
class BluetoothMessage {
  final String senderId;
  final String content;
  final String timestamp;
  final String? recipientId; // Optional, for direct messages

  BluetoothMessage({
    required this.senderId,
    required this.content,
    required this.timestamp,
    this.recipientId,
  });

  Map<String, dynamic> toJson() => {
    'senderId': senderId,
    'content': content,
    'timestamp': timestamp,
    'recipientId': recipientId,
  };

  factory BluetoothMessage.fromJson(Map<String, dynamic> json) => BluetoothMessage(
    senderId: json['senderId'],
    content: json['content'],
    timestamp: json['timestamp'],
    recipientId: json['recipientId'],
  );
}

// Custom Service and Characteristic UUIDs for messaging
// These are arbitrary UUIDs in the standard format.
// All devices in your "mesh" would need to implement this service.
final Guid SERVICE_UUID = Guid("4fafc201-1fb5-459e-8fcc-c5c9c331914b");
final Guid CHARACTERISTIC_UUID = Guid("beb5483e-36e1-4688-b7f5-ea07361b26a8");

class BluetoothProvider extends ChangeNotifier {
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  List<ScanResult> _scanResults = [];
  Map<String, BluetoothDevice> _connectedDevices = {}; // Map device ID to device
  Map<String, BluetoothCharacteristic> _writeCharacteristics = {}; // Store writable characteristics by device ID
  Map<String, StreamSubscription<List<int>>> _notificationSubscriptions = {}; // Store notification subscriptions

  List<BluetoothMessage> _receivedMessages = [];
  bool _isScanning = false;
  String _localDeviceId = 'Unknown'; // Placeholder, typically derived from device info

  final FlutterBlePeripheral _blePeripheral = FlutterBlePeripheral(); // Initialize the peripheral instance
  bool _isAdvertising = false; // New state variable for advertising status

  // Getters for UI access
  BluetoothAdapterState get adapterState => _adapterState;
  List<ScanResult> get scanResults => _scanResults;
  List<BluetoothDevice> get connectedDevices => _connectedDevices.values.toList();
  List<BluetoothMessage> get receivedMessages => _receivedMessages;
  bool get isScanning => _isScanning;
  String get localDeviceId => _localDeviceId;
  bool get isAdvertising => _isAdvertising; // New getter for advertising status

  StreamSubscription? _scanSubscription;
  StreamSubscription? _adapterStateSubscription;

  BluetoothProvider() {
    _initializeBluetooth();
  }

  Future<void> _initializeBluetooth() async {
    // Listen for adapter state changes
    _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      _adapterState = state;
      notifyListeners();
      if (state == BluetoothAdapterState.on) {
        startScan(); // Start scanning when Bluetooth is on
        startAdvertising(); // New: Start advertising when Bluetooth is on
      } else {
        _stopScan();
        _disconnectAllDevices();
        stopAdvertising(); // New: Stop advertising when Bluetooth is off
      }
    });

    // Request permissions on initialization
    await requestPermissions();

    // Get initial adapter state
    _adapterState = await FlutterBluePlus.adapterState.first;
    notifyListeners();

    // Set a placeholder for local device ID. In a real app, this would be a unique user ID or device ID.
    _localDeviceId = 'User_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    notifyListeners();

    if (_adapterState == BluetoothAdapterState.on) {
      startScan();
      startAdvertising(); // New: Start advertising on initial load if Bluetooth is already on
    }
  }

  Future<void> requestPermissions() async {
    // Request Bluetooth permissions for BLE
    var bluetoothConnectStatus = await Permission.bluetoothConnect.status;
    var bluetoothScanStatus = await Permission.bluetoothScan.status;
    var bluetoothAdvertiseStatus = await Permission.bluetoothAdvertise.status; // For acting as peripheral
    var locationStatus = await Permission.locationWhenInUse.status; // Required for BLE scanning on Android

    if (!bluetoothConnectStatus.isGranted) {
      await Permission.bluetoothConnect.request();
    }
    if (!bluetoothScanStatus.isGranted) {
      await Permission.bluetoothScan.request();
    }
    if (!bluetoothAdvertiseStatus.isGranted) {
      await Permission.bluetoothAdvertise.request();
    }
    if (!locationStatus.isGranted) {
      await Permission.locationWhenInUse.request();
    }

    if (await Permission.bluetoothConnect.isGranted &&
        await Permission.bluetoothScan.isGranted &&
        await Permission.bluetoothAdvertise.isGranted &&
        await Permission.locationWhenInUse.isGranted) {
      print("All necessary Bluetooth permissions granted.");
    } else {
      print("Some Bluetooth permissions were not granted.");
    }
  }

  void startScan() {
    if (_isScanning) return;
    _isScanning = true;
    _scanResults.clear();
    notifyListeners();

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      // Filter results to only include devices advertising our custom service UUID
      // In a real mesh, you might look for any device advertising a specific flag
      final filteredResults = results.where((r) =>
      r.advertisementData.serviceUuids.contains(SERVICE_UUID.toString().toUpperCase()) ||
          r.device.platformName.isNotEmpty // Simple filter: only show devices with a name
      ).toList();

      for (var newResult in filteredResults) {
        final existingIndex = _scanResults.indexWhere((r) => r.device.remoteId == newResult.device.remoteId);
        if (existingIndex >= 0) {
          _scanResults[existingIndex] = newResult; // Update existing scan result
        } else {
          _scanResults.add(newResult);
        }
      }
      notifyListeners();
    }, onError: (e) {
      print("Scan error: $e");
      _isScanning = false;
      notifyListeners();
    });

    // Start scanning for devices
    FlutterBluePlus.startScan(timeout: Duration(seconds: 10), withServices: [SERVICE_UUID]);
    print("Started BLE scan.");

    // Stop scan after timeout
    Future.delayed(Duration(seconds: 10), () {
      _stopScan();
    });
  }

  void _stopScan() {
    FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
    _isScanning = false;
    notifyListeners();
    print("Stopped BLE scan.");
  }

  // New: Method to start BLE advertising
  Future<void> startAdvertising() async {
    if (_isAdvertising) return;

    // Define the advertisement data
    final AdvertiseData advertiseData = AdvertiseData(
      serviceUuid: SERVICE_UUID.toString(), // Corrected: Use serviceUuid instead of serviceUuids
      includeDeviceName: true, // Include the device's name in the advertisement
      // You can add manufacturer data or service data here for more complex discovery
    );

    // Define the advertisement settings
    final AdvertiseSettings advertiseSettings = AdvertiseSettings(
      advertiseMode: AdvertiseMode.advertiseModeLowPower, // ✅ Corrected
      txPowerLevel: AdvertiseTxPower.advertiseTxPowerHigh, // ✅ Corrected
      timeout: 0, // Advertise indefinitely
    );

    try {
      await _blePeripheral.start(advertiseData: advertiseData, advertiseSettings: advertiseSettings);
      _isAdvertising = true;
      print("Started BLE advertising.");
    } catch (e) {
      print("Failed to start BLE advertising: $e");
      _isAdvertising = false;
    }
    notifyListeners();
  }

  // New: Method to stop BLE advertising
  Future<void> stopAdvertising() async {
    if (!_isAdvertising) return;
    try {
      await _blePeripheral.stop();
      _isAdvertising = false;
      print("Stopped BLE advertising.");
    } catch (e) {
      print("Error stopping BLE advertising: $e");
    }
    notifyListeners();
  }


  Future<void> connectToDevice(BluetoothDevice device) async {
    if (_connectedDevices.containsKey(device.remoteId.str)) {
      print("Already connected to ${device.platformName} (${device.remoteId.str})");
      return;
    }

    try {
      print('Connecting to ${device.platformName} (${device.remoteId.str})...');
      await device.connect(timeout: Duration(seconds: 15));
      _connectedDevices[device.remoteId.str] = device;
      notifyListeners();
      print('Connected to ${device.platformName} (${device.remoteId.str})');

      // Discover services and characteristics
      List<BluetoothService> services = await device.discoverServices();
      BluetoothCharacteristic? writeChar;
      BluetoothCharacteristic? notifyChar;

      for (var service in services) {
        if (service.uuid == SERVICE_UUID) {
          for (var characteristic in service.characteristics) {
            if (characteristic.uuid == CHARACTERISTIC_UUID) {
              if (characteristic.properties.write) {
                writeChar = characteristic;
              }
              if (characteristic.properties.notify) {
                notifyChar = characteristic;
              }
            }
          }
        }
      }

      if (writeChar != null && notifyChar != null) {
        _writeCharacteristics[device.remoteId.str] = writeChar;
        print("Found write characteristic for ${device.platformName}");

        // Subscribe to notifications for incoming messages
        await notifyChar.setNotifyValue(true);
        _notificationSubscriptions[device.remoteId.str] = notifyChar.value.listen((value) {
          String messageString = utf8.decode(value);
          try {
            Map<String, dynamic> messageJson = jsonDecode(messageString);
            BluetoothMessage message = BluetoothMessage.fromJson(messageJson);
            _receivedMessages.add(message);
            print("Received from ${message.senderId} (via ${device.platformName}): ${message.content}");
            notifyListeners();

            // Basic mesh forwarding: if the message is not for me, forward it
            // This is a very simple broadcast. A real mesh would need more logic.
            if (message.recipientId == null || message.recipientId != _localDeviceId) {
              _forwardMessage(message, excludeDeviceId: device.remoteId.str);
            }

          } catch (e) {
            _receivedMessages.add(BluetoothMessage(
              senderId: device.platformName,
              content: messageString,
              timestamp: DateTime.now().toIso8601String(),
            ));
            print("Received plain text from ${device.platformName}: $messageString");
            notifyListeners();
          }
        });
        print("Subscribed to notifications for ${device.platformName}");
      } else {
        print("Required service or characteristic not found on ${device.platformName}. Disconnecting.");
        disconnectFromDevice(device);
      }

      // Listen for device state changes (e.g., disconnection)
      device.state.listen((BluetoothConnectionState state) {
        if (state == BluetoothConnectionState.disconnected) {
          print('Disconnected from ${device.platformName} (${device.remoteId.str}) automatically.');
          _cleanUpDevice(device.remoteId.str);
        }
      });

    } catch (e) {
      print('Failed to connect to ${device.platformName} (${device.remoteId.str}): $e');
      _cleanUpDevice(device.remoteId.str); // Clean up on connection failure
      // Optionally, show a snackbar or error message
    }
  }

  Future<void> disconnectFromDevice(BluetoothDevice device) async {
    if (_connectedDevices.containsKey(device.remoteId.str)) {
      print('Disconnecting from ${device.platformName} (${device.remoteId.str})...');
      try {
        await device.disconnect();
        _cleanUpDevice(device.remoteId.str);
        print('Disconnected from ${device.platformName} (${device.remoteId.str}) manually.');
      } catch (e) {
        print('Error disconnecting from ${device.platformName}: $e');
      }
    }
  }

  void _disconnectAllDevices() {
    _connectedDevices.values.forEach((device) {
      device.disconnect(); // Disconnect without waiting for each
    });
    _connectedDevices.clear();
    _writeCharacteristics.clear();
    _notificationSubscriptions.values.forEach((sub) => sub.cancel());
    _notificationSubscriptions.clear();
    notifyListeners();
  }

  void _cleanUpDevice(String deviceId) {
    _connectedDevices.remove(deviceId);
    _writeCharacteristics.remove(deviceId);
    _notificationSubscriptions[deviceId]?.cancel();
    _notificationSubscriptions.remove(deviceId);
    notifyListeners();
  }

  Future<void> sendMessage(String content, {String? recipientDeviceId}) async {
    if (_adapterState != BluetoothAdapterState.on) {
      print("Bluetooth adapter is not on.");
      return;
    }

    final message = BluetoothMessage(
      senderId: _localDeviceId,
      content: content,
      timestamp: DateTime.now().toIso8601String(),
      recipientId: recipientDeviceId,
    );
    final messageBytes = utf8.encode(jsonEncode(message.toJson()));

    _receivedMessages.add(message); // Add own sent message to local view
    notifyListeners();

    if (recipientDeviceId != null) {
      // Send to a specific recipient
      final characteristic = _writeCharacteristics[recipientDeviceId];
      if (characteristic != null) {
        try {
          await characteristic.write(messageBytes, withoutResponse: characteristic.properties.writeWithoutResponse);
          print("Sent direct message to $recipientDeviceId: $content");
        } catch (e) {
          print("Failed to send direct message to $recipientDeviceId: $e");
        }
      } else {
        print("Characteristic not found for recipient $recipientDeviceId. Is device connected and service discovered?");
      }
    } else {
      // Broadcast to all connected devices
      for (var entry in _connectedDevices.entries) {
        final deviceId = entry.key;
        final characteristic = _writeCharacteristics[deviceId];
        if (characteristic != null) {
          try {
            await characteristic.write(messageBytes, withoutResponse: characteristic.properties.writeWithoutResponse);
            print("Broadcasted message to $deviceId: $content");
          } catch (e) {
            print("Failed to broadcast message to $deviceId: $e");
          }
        }
      }
    }
  }

  // Basic message forwarding for mesh-like behavior (within connected devices)
  void _forwardMessage(BluetoothMessage message, {String? excludeDeviceId}) async {
    final messageBytes = utf8.encode(jsonEncode(message.toJson()));
    for (var entry in _connectedDevices.entries) {
      final deviceId = entry.key;
      final characteristic = _writeCharacteristics[deviceId];
      if (characteristic != null && deviceId != excludeDeviceId) {
        try {
          await characteristic.write(messageBytes, withoutResponse: characteristic.properties.writeWithoutResponse);
          print("Forwarded message to $deviceId");
        } catch (e) {
          print("Failed to forward message to $deviceId: $e");
        }
      }
    }
  }

  @override
  void dispose() {
    _stopScan();
    _disconnectAllDevices();
    _adapterStateSubscription?.cancel();
    stopAdvertising(); // New: Stop advertising on dispose
    super.dispose();
  }
}
