// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class PermissionPage extends StatelessWidget {
  const PermissionPage({super.key});

  Future<void> _requestPermission(BuildContext context, Permission permission,
      String permissionName) async {
    final status = await permission.status;

    if (status.isDenied || status.isPermanentlyDenied) {
      final re = await permission.request();
      if (re.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$permissionName permission granted')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$permissionName permission denied')));
      }
    } else if (status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$permissionName permission already granted')));
    }
  }

  Future<void> _requestStoragePermission(BuildContext context) async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    if (androidInfo.version.sdkInt >= 30) {
      var result = await Permission.manageExternalStorage.request();
      if (result.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Manage External Storage permission granted')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Manage External Storage permission denied')));
      }
    } else {
      _requestPermission(context, Permission.storage, 'Storage');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permission Handler'),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.mic),
            title: const Text('Microphone Permission'),
            subtitle: const Text('Click to give microphone access'),
            onTap: () => _requestPermission(
                context, Permission.microphone, 'Microphone'),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Camera Permission'),
            subtitle: const Text('Click to give camera access'),
            onTap: () =>
                _requestPermission(context, Permission.camera, 'Camera'),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Photo Library Permission'),
            subtitle: const Text('Click to give photo library access'),
            onTap: () =>
                _requestPermission(context, Permission.photos, 'Photo Library'),
          ),
          ListTile(
            leading: const Icon(Icons.location_on),
            title: const Text('Location Permission'),
            subtitle: const Text('Click to give location access'),
            onTap: () =>
                _requestPermission(context, Permission.location, 'Location'),
          ),
          ListTile(
            leading: const Icon(Icons.folder),
            title: const Text('Storage Permission'),
            subtitle: const Text('Click to give storage access'),
            onTap: () => _requestStoragePermission(context),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Open App Settings'),
            subtitle: const Text('Click to open app permission settings'),
            onTap: () {
              openAppSettings();
            },
          ),
          ListTile(
            leading: const Icon(Icons.apps),
            title: const Text('Request Multiple Permissions'),
            subtitle: const Text('Click to request multiple permissions'),
            onTap: () async {
              Map<Permission, PermissionStatus> statuses = await [
                Permission.microphone,
                Permission.camera,
                Permission.photos,
                Permission.location,
                Permission.manageExternalStorage
              ].request();

              statuses.forEach((permission, status) {
                final permissionName = permission.toString().split('.').last;
                if (status.isGranted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('$permissionName permission granted')));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('$permissionName permission denied')));
                }
              });
            },
          ),
        ],
      ),
    );
  }
}
