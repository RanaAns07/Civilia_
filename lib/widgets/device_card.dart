import 'package:flutter/material.dart';
import '../models/bluetooth_device_model.dart';

class DeviceCard extends StatelessWidget {
  final BluetoothDeviceModel device;

  const DeviceCard({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          Icons.bluetooth,
          color: device.isConnected ? Colors.blue : Colors.grey,
        ),
        title: Text(device.name),
        subtitle: Text(device.id),
        trailing: device.signalStrength != null
            ? Text('${device.signalStrength} dBm')
            : null,
        onTap: () {
          // Handle connection
        },
      ),
    );
  }
}