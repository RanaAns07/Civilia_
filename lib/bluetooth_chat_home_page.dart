// import 'dart:async';
// import 'dart:io';
//
// import 'package:flutter/material.dart';
// import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';
// import 'package:permission_handler/permission_handler.dart';
//
// // Import the chat screen
// import 'package:civilia_app/chat_screen.dart'; // IMPORTANT: Replace 'your_app_name' with your actual project name
//
// // Define a unique service type for your application
// // This string is crucial for devices to discover each other.
// const String serviceType = 'my-bitchat-service';
//
// class BluetoothChatHomePage extends StatefulWidget {
//   const BluetoothChatHomePage({Key? key}) : super(key: key);
//
//   @override
//   State<BluetoothChatHomePage> createState() => _BluetoothChatHomePageState();
// }
//
// class _BluetoothChatHomePageState extends State<BluetoothChatHomePage> {
//   // Initialize NearbyService, which handles the underlying Bluetooth/Wi-Fi Direct communication.
//   final NearbyService nearbyService = NearbyService();
//
//   // Lists to hold discovered devices (those advertising their presence)
//   // and connected devices (those with an active chat session).
//   List<Device> discoveredDevices = [];
//   List<Device> connectedDevices = [];
//
//   // Stream subscriptions are used to listen for updates from the NearbyService.
//   // We need to cancel these subscriptions in dispose() to prevent memory leaks.
//   StreamSubscription<List<Device>>? devicesSubscription;
//   StreamSubscription<List<Device>>? connectedDevicesSubscription;
//   StreamSubscription<String>? receivedMessageSubscription;
//   StreamSubscription<dynamic>? stateSubscription;
//
//   // Flags to track the current state of advertising and browsing.
//   bool isAdvertising = false;
//   bool isBrowsing = false;
//   bool isInitialized = false; // Tracks if the NearbyService has been initialized.
//
//   @override
//   void initState() {
//     super.initState();
//     _init(); // Start the initialization process when the widget is created.
//   }
//
//   @override
//   void dispose() {
//     // Cancel all active stream subscriptions.
//     devicesSubscription?.cancel();
//     connectedDevicesSubscription?.cancel();
//     receivedMessageSubscription?.cancel();
//     stateSubscription?.cancel();
//
//     // Stop advertising and browsing to release resources.
//     nearbyService.stopAdvertising();
//     nearbyService.stopBrowsingForPeers();
//     super.dispose();
//   }
//
//   // --- Initialization and Permission Handling ---
//   // This method handles requesting necessary permissions and initializing the NearbyService.
//   Future<void> _init() async {
//     // Request Bluetooth and Location permissions first.
//     await _requestPermissions();
//
//     // Initialize the NearbyService with a unique service type and strategy.
//     // The callback indicates when the service is running.
//     await nearbyService.init(
//       serviceType: serviceType,
//       // P2P_CLUSTER allows multiple devices to connect to each other.
//       // Other strategies like P2P_STAR (one central, many peripherals)
//       // or P2P_POINT_TO_POINT (only two devices) can also be used.
//       strategy: Strategy.P2P_CLUSTER,
//       callback: (isRunning) {
//         setState(() {
//           isInitialized = isRunning;
//         });
//         if (isRunning) {
//           _setupListeners(); // If initialized successfully, set up data listeners.
//         }
//       },
//     );
//   }
//
//   // Requests necessary Bluetooth and Location permissions.
//   // On Android, location permission is often required for Bluetooth scanning.
//   Future<void> _requestPermissions() async {
//     // Android-specific Bluetooth permissions for modern Android versions (12+).
//     if (Platform.isAndroid) {
//       await Permission.bluetoothScan.request();
//       await Permission.bluetoothAdvertise.request();
//       await Permission.bluetoothConnect.request();
//     }
//
//     // Location permission is crucial for discovering nearby Bluetooth devices on Android.
//     await Permission.locationWhenInUse.request();
//   }
//
//   // --- Setup Listeners for NearbyService Events ---
//   // This method sets up listeners for various events from the NearbyService,
//   // such as discovered devices, connected devices, and received messages.
//   void _setupListeners() {
//     // Listens for updates to the list of discovered nearby devices.
//     devicesSubscription = nearbyService.devicesStream.listen((devices) {
//       setState(() {
//         discoveredDevices = devices;
//       });
//     });
//
//     // Listens for updates to the list of connected devices.
//     connectedDevicesSubscription = nearbyService.connectedDevicesStream.listen((devices) {
//       setState(() {
//         connectedDevices = devices;
//       });
//       // If a new device connects and we are not already on a chat screen,
//       // navigate to the ChatScreen.
//       // This assumes a single chat session for simplicity. For multiple chats,
//       // you'd manage a list of chat screens or a more complex routing.
//       if (devices.isNotEmpty && !ModalRoute.of(context)!.isCurrent) {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => ChatScreen(
//               nearbyService: nearbyService,
//               connectedDevice: devices.first, // Pass the first connected device.
//             ),
//           ),
//         );
//       }
//     });
//
//     // Listens for incoming messages from any connected device.
//     // The message is a JSON string, which needs to be parsed.
//     receivedMessageSubscription = nearbyService.messagesStream.listen((message) {
//       // This listener is primarily for the ChatScreen, but can show global alerts.
//       _showMessage('Message from ${message['device_id'] ?? 'Unknown'}: ${message['message'] ?? 'No Message'}');
//     });
//
//     // Listens for changes in the overall session state (connecting, connected, etc.).
//     stateSubscription = nearbyService.stateStream.listen((state) {
//       switch (state) {
//         case SessionState.notConnected:
//           _showMessage('Not Connected');
//           break;
//         case SessionState.connecting:
//           _showMessage('Connecting...');
//           break;
//         case SessionState.connected:
//           _showMessage('Connected!');
//           break;
//         case SessionState.failed:
//           _showMessage('Connection Failed!');
//           break;
//         case SessionState.none:
//           _showMessage('No session state');
//           break;
//       }
//     });
//   }
//
//   // --- UI Helper for Messages ---
//   // Displays a SnackBar message at the bottom of the screen.
//   void _showMessage(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message)),
//     );
//   }
//
//   // --- Bluetooth Actions ---
//   // Starts advertising the device's presence to nearby browsers.
//   Future<void> _startAdvertising() async {
//     if (!isInitialized) {
//       _showMessage('Nearby service not initialized. Please wait.');
//       return;
//     }
//     await nearbyService.startAdvertisingPeer();
//     setState(() {
//       isAdvertising = true;
//     });
//     _showMessage('Advertising started. Other devices can now find you.');
//   }
//
//   // Stops advertising the device's presence.
//   Future<void> _stopAdvertising() async {
//     await nearbyService.stopAdvertising();
//     setState(() {
//       isAdvertising = false;
//     });
//     _showMessage('Advertising stopped.');
//   }
//
//   // Starts browsing for nearby devices that are advertising.
//   Future<void> _startBrowsing() async {
//     if (!isInitialized) {
//       _showMessage('Nearby service not initialized. Please wait.');
//       return;
//     }
//     await nearbyService.startBrowsingForPeers();
//     setState(() {
//       isBrowsing = true;
//     });
//     _showMessage('Browsing started. Looking for nearby devices...');
//   }
//
//   // Stops browsing for nearby devices.
//   Future<void> _stopBrowsing() async {
//     await nearbyService.stopBrowsingForPeers();
//     setState(() {
//       isBrowsing = false;
//     });
//     _showMessage('Browsing stopped.');
//   }
//
//   // Invites a discovered device to connect.
//   Future<void> _inviteDevice(Device device) async {
//     _showMessage('Inviting ${device.deviceName ?? device.deviceId}...');
//     await nearbyService.invitePeer(
//       deviceId: device.deviceId,
//       deviceName: device.deviceName,
//     );
//   }
//
//   // Disconnects from a previously connected device.
//   Future<void> _disconnectFromDevice(Device device) async {
//     await nearbyService.disconnectPeer(deviceId: device.deviceId);
//     _showMessage('Disconnected from ${device.deviceName ?? device.deviceId}');
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Bluetooth Chat Home'),
//         elevation: 4,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Display initialization status.
//             Text(
//               'Initialization Status: ${isInitialized ? "Ready" : "Initializing..."}',
//               style: TextStyle(
//                 color: isInitialized ? Colors.green : Colors.orange,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 20),
//             // Buttons for starting/stopping advertising.
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: [
//                 ElevatedButton.icon(
//                   onPressed: isInitialized && !isAdvertising ? _startAdvertising : null,
//                   icon: const Icon(Icons.wifi_tethering),
//                   label: const Text('Start Advertising'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blueAccent,
//                     foregroundColor: Colors.white,
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                   ),
//                 ),
//                 ElevatedButton.icon(
//                   onPressed: isAdvertising ? _stopAdvertising : null,
//                   icon: const Icon(Icons.wifi_off),
//                   label: const Text('Stop Advertising'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.redAccent,
//                     foregroundColor: Colors.white,
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 10),
//             // Buttons for starting/stopping browsing.
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: [
//                 ElevatedButton.icon(
//                   onPressed: isInitialized && !isBrowsing ? _startBrowsing : null,
//                   icon: const Icon(Icons.search),
//                   label: const Text('Start Browsing'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blueAccent,
//                     foregroundColor: Colors.white,
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                   ),
//                 ),
//                 ElevatedButton.icon(
//                   onPressed: isBrowsing ? _stopBrowsing : null,
//                   icon: const Icon(Icons.stop),
//                   label: const Text('Stop Browsing'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.redAccent,
//                     foregroundColor: Colors.white,
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//             // Section for displaying discovered devices.
//             Text(
//               'Discovered Devices (${discoveredDevices.length}):',
//               style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
//             ),
//             Expanded(
//               child: ListView.builder(
//                 itemCount: discoveredDevices.length,
//                 itemBuilder: (context, index) {
//                   final device = discoveredDevices[index];
//                   return Card(
//                     margin: const EdgeInsets.symmetric(vertical: 4.0),
//                     elevation: 2,
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                     child: ListTile(
//                       title: Text(
//                         device.deviceName ?? 'Unknown Device',
//                         style: const TextStyle(fontWeight: FontWeight.w500),
//                       ),
//                       subtitle: Text(device.deviceId),
//                       trailing: ElevatedButton(
//                         onPressed: () => _inviteDevice(device),
//                         child: const Text('Connect'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.green,
//                           foregroundColor: Colors.white,
//                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                         ),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//             const SizedBox(height: 20),
//             // Section for displaying connected devices.
//             Text(
//               'Connected Devices (${connectedDevices.length}):',
//               style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
//             ),
//             Expanded(
//               child: ListView.builder(
//                 itemCount: connectedDevices.length,
//                 itemBuilder: (context, index) {
//                   final device = connectedDevices[index];
//                   return Card(
//                     margin: const EdgeInsets.symmetric(vertical: 4.0),
//                     elevation: 2,
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                     child: ListTile(
//                       title: Text(
//                         device.deviceName ?? 'Unknown Device',
//                         style: const TextStyle(fontWeight: FontWeight.w500),
//                       ),
//                       subtitle: Text(device.deviceId),
//                       trailing: ElevatedButton(
//                         onPressed: () => _disconnectFromDevice(device),
//                         child: const Text('Disconnect'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.orange,
//                           foregroundColor: Colors.white,
//                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                         ),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
