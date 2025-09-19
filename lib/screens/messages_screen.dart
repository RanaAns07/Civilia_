import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide BluetoothService;
import '../services/bluetooth_service.dart';

class MessagingScreen extends StatefulWidget {
  const MessagingScreen({super.key});

  @override
  _MessagingScreenState createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  final TextEditingController _messageController = TextEditingController();
  List<String> messages = [];
  List<BluetoothDevice> availableDevices = [];
  int connectedDevicesCount = 0;

  @override
  void initState() {
    super.initState();
    _startDiscovery();
  }

  void _startDiscovery() {
    MyBluetoothService().discoverDevices().listen((results) {
      setState(() {
        availableDevices = results.map((r) => r.device).toList();
        // Filter devices that have your app installed
        // You might need to implement additional handshake protocol
      });
    });

    // Auto-connect logic would go here
  }

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      MyBluetoothService().sendMessage(_messageController.text);
      setState(() {
        messages.add("You: ${_messageController.text}");
      });
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Bluetooth Chat"),
        actions: [
          Chip(
            label: Text("$connectedDevicesCount connected"),
            backgroundColor: Colors.blue.shade100,
          ),
          SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(messages[index]),
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
                    decoration: InputDecoration(hintText: "Type a message"),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    MyBluetoothService().disconnect();
    _messageController.dispose();
    super.dispose();
  }
}