import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';
import 'dart:convert'; // For utf8 encoding/decoding
import 'package:civilia_app/widgets/bottom_navigation_bar.dart'; // Import CustomBottomNavigationBar

// Define custom UUIDs for our BLE service and characteristic
// These are unique identifiers for your custom BLE communication
// You can generate your own UUIDs online (e.g., uuidgenerator.net)
const String serviceUuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
const String characteristicUuid = "beb5483e-36e1-4501-b57f-b02400000001";

class BleChatScreen extends StatefulWidget {
  const BleChatScreen({super.key});

  @override
  State<BleChatScreen> createState() => _BleChatScreenState();
}

class _BleChatScreenState extends State<BleChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<String> _messages = [];
  bool _isScanning = false;
  bool _isConnected = false;
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeCharacteristic;
  StreamSubscription<List<int>>? _characteristicSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;
  StreamSubscription<BluetoothAdapterState>? _bluetoothAdapterStateSubscription; // For Bluetooth state changes

  int _selectedIndex = 2; // Default to Messages tab for BLE Chat Screen

  @override
  void initState() {
    super.initState();
    _bluetoothAdapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      if (state != BluetoothAdapterState.on) {
        _showSnackBar('Bluetooth is OFF. Please turn it ON.', isError: true);
      }
    });
    _checkBluetoothState();
  }

  @override
  void dispose() {
    _characteristicSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    _bluetoothAdapterStateSubscription?.cancel();
    _connectedDevice?.disconnect(); // Disconnect from BLE device
    FlutterBluePlus.stopScan(); // Stop any ongoing scan
    _messageController.dispose();
    super.dispose();
  }

  // Check if Bluetooth is on and request permissions
  void _checkBluetoothState() async {
    var bluetoothState = await FlutterBluePlus.adapterState.first;
    if (bluetoothState != BluetoothAdapterState.on) {
      _showSnackBar('Bluetooth is OFF. Please turn it ON.', isError: true);
    }
  }

  // Show a SnackBar message
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Central Role: Scan for peripherals
  void _startScan() async {
    if (_isScanning) return;
    setState(() {
      _isScanning = true;
      _messages.add("Scanning for devices...");
    });

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
      FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult r in results) {
          debugPrint('${r.device.platformName} found! RSSI: ${r.rssi}');
          // Filter for devices advertising our specific service UUID
          // Note: For this to work, the *other* device needs to be advertising this UUID.
          if (r.advertisementData.serviceUuids.contains(serviceUuid.toUpperCase())) {
            _messages.add("Found device: ${r.device.platformName} (${r.device.remoteId})");
            _connectToDevice(r.device);
            FlutterBluePlus.stopScan(); // Stop scanning once found
            break;
          }
        }
      });
      await FlutterBluePlus.isScanning.where((val) => val == false).first;
      setState(() {
        _isScanning = false;
        _messages.add("Scan stopped.");
      });
    } catch (e) {
      debugPrint("Scan error: $e");
      _showSnackBar("Scan failed: $e", isError: true);
      setState(() {
        _isScanning = false;
      });
    }
  }

  // Central Role: Connect to a discovered peripheral
  void _connectToDevice(BluetoothDevice device) async {
    if (_isConnected) return;
    setState(() {
      _messages.add("Connecting to ${device.platformName}...");
    });

    _connectionStateSubscription = device.connectionState.listen((state) async {
      if (state == BluetoothConnectionState.connected) {
        setState(() {
          _isConnected = true;
          _connectedDevice = device;
          _messages.add("Connected to ${device.platformName}");
        });
        _discoverServices(device);
      } else if (state == BluetoothConnectionState.disconnected) {
        setState(() {
          _isConnected = false;
          _connectedDevice = null;
          _writeCharacteristic = null;
          _messages.add("Disconnected from ${device.platformName}");
        });
        _showSnackBar("Disconnected from ${device.platformName}", isError: true);
      }
    });

    try {
      await device.connect();
    } catch (e) {
      debugPrint("Connection error: $e");
      _showSnackBar("Connection failed: $e", isError: true);
      setState(() {
        _isConnected = false;
      });
    }
  }

  // Central Role: Discover services and characteristics on the connected device
  void _discoverServices(BluetoothDevice device) async {
    try {
      List<BluetoothService> services = await device.discoverServices();
      for (BluetoothService service in services) {
        if (service.uuid.toString().toUpperCase() == serviceUuid.toUpperCase()) {
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            if (characteristic.uuid.toString().toUpperCase() == characteristicUuid.toUpperCase()) {
              setState(() {
                _writeCharacteristic = characteristic;
              });
              _messages.add("Found characteristic for writing.");
              _characteristicSubscription = characteristic.lastValueStream.listen((value) {
                if (value.isNotEmpty) {
                  String receivedMessage = utf8.decode(value);
                  setState(() {
                    _messages.add("Received: $receivedMessage");
                  });
                }
              });
              await characteristic.setNotifyValue(true); // Enable notifications
              _showSnackBar("Ready to chat!");
              return;
            }
          }
        }
      }
      _showSnackBar("Required service/characteristic not found.", isError: true);
    } catch (e) {
      debugPrint("Service discovery error: $e");
      _showSnackBar("Service discovery failed: $e", isError: true);
    }
  }

  // Send a message via BLE characteristic
  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _writeCharacteristic == null || !_isConnected) {
      _showSnackBar("Not connected or no message to send.", isError: true);
      return;
    }

    String message = _messageController.text.trim();
    _messageController.clear();
    setState(() {
      _messages.add("You: $message");
    });

    try {
      await _writeCharacteristic!.write(utf8.encode(message), withoutResponse: true);
      _showSnackBar("Message sent!");
    } catch (e) {
      debugPrint("Send message error: $e");
      _showSnackBar("Failed to send message: $e", isError: true);
    }
  }

  // Handles navigation for the bottom navigation bar
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0: // Map
        Navigator.of(context).pushReplacementNamed('/home');
        break;
      case 1: // First Aid
        Navigator.of(context).pushReplacementNamed('/firstAidCategories');
        break;
      case 2: // Messages (stay on this screen, or navigate to general message list if preferred)
      // If you want to go to the main message list, use:
        Navigator.of(context).pushReplacementNamed('/messageList');
        break;
      case 3: // Profile
        Navigator.of(context).pushReplacementNamed('/profile');
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BLE Chat Demo (Central Role)'),
        backgroundColor: Colors.pink,
        leading: IconButton( // Added back button here
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.of(context).pop(); // Pops the current screen off the stack
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _isScanning ? null : _startScan,
                      child: Text(_isScanning ? 'Scanning...' : 'Start Scan (Central)'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _isConnected ? 'Connected to: ${_connectedDevice?.platformName ?? "Unknown"}' : 'Status: Disconnected',
                  style: TextStyle(
                    color: _isConnected ? Colors.greenAccent : Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(_messages[index]),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Enter message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigationBar( // Add the bottom navigation bar
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
