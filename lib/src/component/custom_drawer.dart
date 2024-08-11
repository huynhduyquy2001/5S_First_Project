import 'package:flutter/material.dart';

class CustomDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const UserAccountsDrawerHeader(
            accountName: Text("George McAllister"),
            accountEmail: Text("georgemcallister@gmail.com"),
            currentAccountPicture: CircleAvatar(
              backgroundImage: AssetImage("assets/images/icon-256x256.png"),
            ),
            decoration: BoxDecoration(color: Color(0xFF4B63B6)),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About us'),
            onTap: () {
              Navigator.pushNamed(context, '/about-us');
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today_outlined),
            title: const Text('Booking'),
            onTap: () {
              Navigator.pushNamed(context, '/booking');
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_bag_outlined),
            title: const Text('Product'),
            onTap: () {
              Navigator.pushNamed(context, '/product');
            },
          ),
          ListTile(
            leading: const Icon(Icons.list_alt_outlined),
            title: const Text('Booking Webview'),
            onTap: () {
              Navigator.pushNamed(context, '/listBookingWebview');
            },
          ),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Permission'),
            onTap: () {
              Navigator.pushNamed(context, '/permission');
            },
          ),
          // ListTile(
          //   leading: const Icon(Icons.web),
          //   title: const Text('Test Webview'),
          //   onTap: () {
          //     Navigator.pushNamed(context, '/test-webview');
          //   },
          // ),

          // ListTile(
          //   leading: const Icon(Icons.list),
          //   title: const Text('Bookings Sqlite'),
          //   onTap: () {
          //     Navigator.pushNamed(context, '/bookings-sqite');
          //   },
          // ),
          // ListTile(
          //   leading: const Icon(Icons.map),
          //   title: const Text('Coordinate'),
          //   onTap: () {
          //     Navigator.pushNamed(context, '/coordinate');
          //   },
          // ),

          ListTile(
            leading: const Icon(Icons.web),
            title: const Text('Webview Khải'),
            onTap: () {
              Navigator.pushNamed(context, '/test-webview-khai');
            },
          ),
          ListTile(
            leading: const Icon(Icons.web),
            title: const Text('Webview Kiệt'),
            onTap: () {
              Navigator.pushNamed(context, '/test-webview-kiet');
            },
          ),
          ListTile(
            leading: const Icon(Icons.web),
            title: const Text('Webview Thảo'),
            onTap: () {
              Navigator.pushNamed(context, '/test-webview-thao');
            },
          ),
          ListTile(
            leading: const Icon(Icons.build),
            title: const Text('Sales vs Coordinate'),
            onTap: () {
              Navigator.pushNamed(context, '/test');
            },
          ),
          ListTile(
            leading: const Icon(Icons.text_fields),
            title: const Text('String concat'),
            onTap: () {
              Navigator.pushNamed(context, '/test-coordinate');
            },
          ),
          ListTile(
            leading: const Icon(Icons.qr_code_scanner),
            title: const Text('Barcode'),
            onTap: () {
              Navigator.pushNamed(context, '/barcode-scanner');
            },
          ),
          // ListTile(
          //   leading: const Icon(Icons.logout),
          //   title: const Text('Sign Out'),
          //   onTap: () {
          //     // Handle the action
          //   },
          // ),
        ],
      ),
    );
  }
}
