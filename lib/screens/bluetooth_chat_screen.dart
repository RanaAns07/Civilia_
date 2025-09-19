import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart'; // Import FlutterBluePlus
import 'package:civilia_app/providers/bluetooth_provider.dart'; // Adjust path if needed
import 'package:google_fonts/google_fonts.dart'; // For consistent styling

class BluetoothChatScreen extends StatefulWidget {
  const BluetoothChatScreen({super.key});

  @override
  State<BluetoothChatScreen> createState() => _BluetoothChatScreenState();
}

class _BluetoothChatScreenState extends State<BluetoothChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  BluetoothDevice? _selectedDevice; // For direct messaging

  @override
  void initState() {
    super.initState();
    // Ensure permissions are requested when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BluetoothProvider>(context, listen: false).requestPermissions();
      // Start scanning immediately when the screen loads
      Provider.of<BluetoothProvider>(context, listen: false).startScan();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bluetoothProvider = Provider.of<BluetoothProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Bluetooth Mesh Chat', style: theme.appBarTheme.titleTextStyle),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: theme.appBarTheme.foregroundColor),
            onPressed: () {
              bluetoothProvider.startScan(); // Restart discovery
            },
          ),
          // Toggle Bluetooth Adapter State (On/Off)
          Switch(
            value: bluetoothProvider.adapterState == BluetoothAdapterState.on,
            onChanged: (bool value) async {
              if (value) {
                await FlutterBluePlus.turnOn();
              } else {
                // Show dialog or snackbar instead of calling deprecated turnOff
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('To turn off Bluetooth, please use system settings.'),
                  ),
                );
              }
            },
            activeColor: theme.colorScheme.primary,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Bluetooth Adapter State and Local Device Info
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bluetooth Adapter: ${bluetoothProvider.adapterState.toString().split('.').last}',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Local Device ID: ${bluetoothProvider.localDeviceId}',
                    style: GoogleFonts.inter(fontSize: 14, color: theme.textTheme.bodyMedium?.color),
                  ),
                  const SizedBox(height: 4),
                  Text( // New: Display advertising status
                    'Advertising: ${bluetoothProvider.isAdvertising ? 'ON' : 'OFF'}',
                    style: GoogleFonts.inter(fontSize: 14, color: bluetoothProvider.isAdvertising ? Colors.green : Colors.red),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Discovered Devices
            Text(
              'Discovered Devices (${bluetoothProvider.isScanning ? 'Scanning...' : 'Done'}):',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
            ),
            Expanded(
              flex: 2,
              child: bluetoothProvider.scanResults.isEmpty
                  ? Center(child: Text('No devices found.', style: GoogleFonts.inter(color: theme.textTheme.bodyMedium?.color)))
                  : ListView.builder(
                itemCount: bluetoothProvider.scanResults.length,
                itemBuilder: (context, index) {
                  ScanResult result = bluetoothProvider.scanResults[index];
                  BluetoothDevice device = result.device;
                  bool isConnected = bluetoothProvider.connectedDevices.any((d) => d.remoteId == device.remoteId); // Corrected: Use remoteId for comparison

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    color: theme.cardColor,
                    child: ListTile(
                      title: Text(
                        device.platformName.isNotEmpty ? device.platformName : 'Unknown Device', // Corrected: Use platformName
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: theme.textTheme.titleMedium?.color),
                      ),
                      subtitle: Text(
                        device.remoteId.str, // Corrected: Use remoteId.str
                        style: GoogleFonts.inter(color: theme.textTheme.bodySmall?.color),
                      ),
                      trailing: isConnected
                          ? ElevatedButton(
                        onPressed: () => bluetoothProvider.disconnectFromDevice(device),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                        child: const Text('Disconnect'),
                      )
                          : ElevatedButton(
                        onPressed: () => bluetoothProvider.connectToDevice(device),
                        style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: theme.colorScheme.onPrimary),
                        child: const Text('Connect'),
                      ),
                      onTap: () {
                        // Select device for direct messaging
                        setState(() {
                          _selectedDevice = device;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Selected ${device.platformName.isNotEmpty ? device.platformName : device.remoteId.str} for direct message.')), // Corrected: Use platformName and remoteId.str
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Received Messages
            Text(
              'Messages:',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
            ),
            Expanded(
              flex: 3,
              child: bluetoothProvider.receivedMessages.isEmpty
                  ? Center(child: Text('No messages yet.', style: GoogleFonts.inter(color: theme.textTheme.bodyMedium?.color)))
                  : ListView.builder(
                reverse: true, // Show latest messages at the bottom
                itemCount: bluetoothProvider.receivedMessages.length,
                itemBuilder: (context, index) {
                  final message = bluetoothProvider.receivedMessages[bluetoothProvider.receivedMessages.length - 1 - index]; // Display in reverse order
                  bool isMe = message.senderId == bluetoothProvider.localDeviceId;
                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isMe ? theme.colorScheme.primary.withOpacity(0.8) : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Text(
                            // Safely get substring, ensuring length is sufficient
                            isMe ? 'You (${message.senderId.length >= 5 ? message.senderId.substring(message.senderId.length - 5) : message.senderId})' : '${message.senderId.length >= 5 ? message.senderId.substring(message.senderId.length - 5) : message.senderId}',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              color: isMe ? theme.colorScheme.onPrimary : theme.textTheme.titleMedium?.color,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            message.content,
                            style: GoogleFonts.inter(
                              color: isMe ? theme.colorScheme.onPrimary : theme.textTheme.bodyLarge?.color,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${DateTime.parse(message.timestamp).toLocal().hour}:${DateTime.parse(message.timestamp).toLocal().minute}',
                            style: GoogleFonts.inter(
                              color: isMe ? theme.colorScheme.onPrimary.withOpacity(0.7) : theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Message Input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: _selectedDevice != null
                          ? 'Message ${_selectedDevice!.platformName.isNotEmpty ? _selectedDevice!.platformName : _selectedDevice!.remoteId.str}...' // Corrected: Use platformName and remoteId.str
                          : 'Broadcast message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.colorScheme.primary),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    style: GoogleFonts.inter(color: theme.textTheme.bodyLarge?.color),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: () {
                    if (_messageController.text.isNotEmpty) {
                      bluetoothProvider.sendMessage(
                        _messageController.text,
                        recipientDeviceId: _selectedDevice?.remoteId.str, // Corrected: Use remoteId.str
                      );
                      _messageController.clear();
                      setState(() {
                        _selectedDevice = null; // Clear selection after sending
                      });
                    }
                  },
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
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

