import 'package:flutter/material.dart';
import 'package:frontend/models/device.dart';
import 'package:frontend/services/device_service.dart';

class DeviceSecurityScreen extends StatefulWidget {
  final String currentDeviceId;
  final DeviceService? deviceService;

  const DeviceSecurityScreen({
    super.key,
    required this.currentDeviceId,
    this.deviceService,
  });

  @override
  State<DeviceSecurityScreen> createState() => _DeviceSecurityScreenState();
}

class _DeviceSecurityScreenState extends State<DeviceSecurityScreen> {
  late final DeviceService _deviceService;
  List<Device> _devices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _deviceService = widget.deviceService ?? DeviceService();
    _fetchDevices();
  }

  Future<void> _fetchDevices() async {
    setState(() => _isLoading = true);
    try {
      final devices = await _deviceService.getDevices();
      setState(() {
        _devices = devices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _revokeDevice(Device device) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Device'),
        content: Text(
          'Are you sure you want to revoke "${device.name}"? '
          'This device will immediately lose messaging capabilities.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _deviceService.revokeDevice(device.id);
      if (success) {
        _fetchDevices();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Security & Active Sessions'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _devices.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final dev = _devices[index];
                final isCurrent = dev.id == widget.currentDeviceId;

                return ListTile(
                  leading: Icon(
                    dev.platform == 'android'
                        ? Icons.phone_android
                        : dev.platform == 'ios'
                            ? Icons.phone_iphone
                            : dev.platform == 'web'
                                ? Icons.web
                                : Icons.laptop,
                    color: isCurrent ? Colors.blue : Colors.grey,
                  ),
                  title: Row(
                    children: [
                      Text(
                        dev.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue),
                          ),
                          child: const Text(
                            'Current Device',
                            style: TextStyle(fontSize: 11, color: Colors.blue),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text('Identity: ${dev.publicIdentityKey.length > 16 ? dev.publicIdentityKey.substring(0, 16) : dev.publicIdentityKey}...'),
                  trailing: isCurrent
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.block, color: Colors.red),
                          onPressed: () => _revokeDevice(dev),
                          tooltip: 'Revoke Device',
                        ),
                );
              },
            ),
    );
  }
}
