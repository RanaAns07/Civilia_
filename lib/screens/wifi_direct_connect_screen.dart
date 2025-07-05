// lib/screens/wifi_direct_connect_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For MethodChannel and EventChannel
import 'package:permission_handler/permission_handler.dart'; // For requesting permissions
import 'package:civilia/main.dart'; // For neonBlue

class WifiDirectConnectScreen extends StatefulWidget {
  const WifiDirectConnectScreen({super.key});

  @override
  State<WifiDirectConnectScreen> createState() => _WifiDirectConnectScreenState();
}

class _WifiDirectConnectScreenState extends State<WifiDirectConnectScreen> {
  // MethodChannel to invoke native Wi-Fi Direct methods
  static const MethodChannel _wifiDirectMethodChannel = MethodChannel('com.civilia.app/wifi_direct_method');
  // EventChannel to receive streams of data (e.g., discovered peers, messages)
  static const EventChannel _wifiDirectEventChannel = EventChannel('com.civilia.app/wifi_direct_event');

  List<String> _discoveredPeers = []; // List of discovered peer device names
  String _connectionStatus = 'Disconnected'; // Current connection status
  final List<String> _chatMessages = []; // List of chat messages
  final TextEditingController _messageController = TextEditingController();
  bool _isDiscovering = false; // To manage discovery state

  @override
  void initState() {
    super.initState();
    _initPlatformChannels();
    _requestPermissions(); // Request necessary permissions on screen load
  }

  @override
  void dispose() {
    _messageController.dispose();
    // TODO: Implement native channel cleanup (e.g., stop discovery, disconnect)
    super.dispose();
  }

  // Request necessary permissions for Wi-Fi Direct
  Future<void> _requestPermissions() async {
    // For Android 12+, NEARBY_WIFI_DEVICES is required for Wi-Fi P2P discovery
    // For older Android versions, ACCESS_FINE_LOCATION is usually sufficient
    // We also need location services enabled for Wi-Fi P2P.
    Map<Permission, PermissionStatus> statuses = await [
      Permission.locationWhenInUse,
      Permission.nearbyWifiDevices, // Android 12+
    ].request();

    if (statuses[Permission.locationWhenInUse] == PermissionStatus.granted) {
      _showSnackBar('Location permission granted.');
    } else {
      _showSnackBar('Location permission denied. Wi-Fi Direct may not work.', isError: true);
    }

    if (statuses[Permission.nearbyWifiDevices] == PermissionStatus.granted) {
      _showSnackBar('Nearby Wi-Fi Devices permission granted.');
    } else if (statuses[Permission.nearbyWifiDevices] == PermissionStatus.denied) {
      _showSnackBar('Nearby Wi-Fi Devices permission denied. Wi-Fi Direct discovery may be limited.', isError: true);
    }
  }

  // Initialize platform channels and set up listeners
  void _initPlatformChannels() {
    // Listen for events from the native side
    _wifiDirectEventChannel.receiveBroadcastStream().listen((dynamic event) {
      debugPrint('Received event from native: $event');
      if (event is Map) {
        switch (event['type']) {
          case 'peers_updated':
            setState(() {
              _discoveredPeers = List<String>.from(event['peers']);
            });
            _showSnackBar('Discovered ${event['peers'].length} peers.');
            break;
          case 'connection_status_changed':
            setState(() {
              _connectionStatus = event['status'];
            });
            _showSnackBar('Connection status: ${event['status']}');
            break;
          case 'message_received':
            setState(() {
              _chatMessages.add('Peer: ${event['message']}');
            });
            _showSnackBar('Message received!');
            break;
          case 'error':
            _showSnackBar('Native Error: ${event['message']}', isError: true);
            break;
        }
      }
    }, onError: (error) {
      debugPrint('Error on event channel: $error');
      _showSnackBar('Error receiving native events: $error', isError: true);
    });
  }

  // Invoke native method to start peer discovery
  Future<void> _startDiscovery() async {
    setState(() {
      _isDiscovering = true;
      _discoveredPeers.clear();
      _showSnackBar('Starting peer discovery...');
    });
    try {
      final String result = await _wifiDirectMethodChannel.invokeMethod('startDiscovery');
      debugPrint('Discovery result: $result');
      if (result == 'Discovery started') {
        // Native side will send updates via EventChannel
      } else {
        _showSnackBar('Failed to start discovery: $result', isError: true);
        setState(() { _isDiscovering = false; });
      }
    } on PlatformException catch (e) {
      debugPrint("Failed to start discovery: '${e.message}'.");
      _showSnackBar("Error starting discovery: ${e.message}", isError: true);
      setState(() { _isDiscovering = false; });
    }
  }

  // Invoke native method to stop peer discovery
  Future<void> _stopDiscovery() async {
    setState(() {
      _isDiscovering = false;
      _showSnackBar('Stopping peer discovery...');
    });
    try {
      final String result = await _wifiDirectMethodChannel.invokeMethod('stopDiscovery');
      debugPrint('Stop discovery result: $result');
      _showSnackBar('Discovery stopped.');
    } on PlatformException catch (e) {
      debugPrint("Failed to stop discovery: '${e.message}'.");
      _showSnackBar("Error stopping discovery: ${e.message}", isError: true);
    }
  }

  // Invoke native method to connect to a selected peer
  Future<void> _connectToPeer(String deviceAddress) async {
    setState(() {
      _connectionStatus = 'Connecting...';
      _showSnackBar('Connecting to $deviceAddress...');
    });
    try {
      final String result = await _wifiDirectMethodChannel.invokeMethod('connectToPeer', {'address': deviceAddress});
      debugPrint('Connection result: $result');
      if (result == 'Connection initiated') {
        // Native side will send updates via EventChannel
      } else {
        _showSnackBar('Failed to connect: $result', isError: true);
        setState(() { _connectionStatus = 'Disconnected'; });
      }
    } on PlatformException catch (e) {
      debugPrint("Failed to connect: '${e.message}'.");
      _showSnackBar("Error connecting: ${e.message}", isError: true);
      setState(() { _connectionStatus = 'Disconnected'; });
    }
  }

  // Invoke native method to disconnect from current peer
  Future<void> _disconnect() async {
    setState(() {
      _connectionStatus = 'Disconnecting...';
      _showSnackBar('Disconnecting...');
    });
    try {
      final String result = await _wifiDirectMethodChannel.invokeMethod('disconnect');
      debugPrint('Disconnect result: $result');
      _showSnackBar('Disconnected.');
      setState(() { _connectionStatus = 'Disconnected'; });
    } on PlatformException catch (e) {
      debugPrint("Failed to disconnect: '${e.message}'.");
      _showSnackBar("Error disconnecting: ${e.message}", isError: true);
      setState(() { _connectionStatus = 'Disconnected'; });
    }
  }

  // Invoke native method to send a message
  Future<void> _sendMessage() async {
    final String message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();
    setState(() {
      _chatMessages.add('You: $message');
    });

    try {
      final String result = await _wifiDirectMethodChannel.invokeMethod('sendMessage', {'message': message});
      debugPrint('Send message result: $result');
      if (result != 'Message sent') {
        _showSnackBar('Failed to send message: $result', isError: true);
      }
    } on PlatformException catch (e) {
      debugPrint("Failed to send message: '${e.message}'.");
      _showSnackBar("Error sending message: ${e.message}", isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
        backgroundColor: isError ? Colors.redAccent : neonBlue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wi-Fi Direct Connect'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Theme.of(context).cardColor,
              margin: const EdgeInsets.only(bottom: 16.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connection Status:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: neonBlue),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _connectionStatus,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: _connectionStatus == 'Connected' ? Colors.greenAccent : Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isDiscovering ? _stopDiscovery : _startDiscovery,
                          icon: Icon(_isDiscovering ? Icons.stop_circle_outlined : Icons.wifi_find),
                          label: Text(_isDiscovering ? 'Stop Discovery' : 'Discover Peers'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isDiscovering ? Colors.redAccent : neonBlue,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _connectionStatus == 'Connected' ? _disconnect : null, // Only enable if connected
                          icon: const Icon(Icons.link_off),
                          label: const Text('Disconnect'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey, // Grey out if not connected
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Text(
              'Discovered Peers:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: neonBlue),
            ),
            const SizedBox(height: 8),
            Expanded(
              flex: 2,
              child: _discoveredPeers.isEmpty
                  ? Center(
                child: Text(
                  _isDiscovering ? 'Searching for devices...' : 'No peers discovered yet. Start discovery.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white54),
                  textAlign: TextAlign.center,
                ),
              )
                  : ListView.builder(
                itemCount: _discoveredPeers.length,
                itemBuilder: (context, index) {
                  final peer = _discoveredPeers[index];
                  return Card(
                    color: Theme.of(context).cardColor,
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    child: ListTile(
                      leading: const Icon(Icons.devices_other, color: neonBlue),
                      title: Text(peer, style: Theme.of(context).textTheme.bodyLarge),
                      trailing: ElevatedButton(
                        onPressed: () => _connectToPeer(peer), // Pass device address (peer name for now)
                        child: const Text('Connect'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: neonBlue,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Chat:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: neonBlue),
            ),
            const SizedBox(height: 8),
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: neonBlue.withOpacity(0.3)),
                ),
                padding: const EdgeInsets.all(8.0),
                child: _chatMessages.isEmpty
                    ? Center(
                  child: Text(
                    'Messages will appear here once connected.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white54),
                    textAlign: TextAlign.center,
                  ),
                )
                    : ListView.builder(
                  reverse: true, // Newest messages at the bottom
                  itemCount: _chatMessages.length,
                  itemBuilder: (context, index) {
                    final message = _chatMessages[index];
                    final bool isMe = message.startsWith('You:');
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: isMe ? neonBlue.withOpacity(0.8) : Colors.grey[700],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          message,
                          style: TextStyle(color: isMe ? Colors.black : Colors.white),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Enter message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    style: Theme.of(context).textTheme.bodyLarge,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  backgroundColor: neonBlue,
                  foregroundColor: Colors.black,
                  mini: true,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
