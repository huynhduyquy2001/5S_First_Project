import 'package:barcode_scan2/platform_wrapper.dart';
import 'package:demo_2/src/ui/about_screen.dart';
import 'package:demo_2/src/ui/barcode_screen.dart';
import 'package:demo_2/src/ui/booking_sqlite/BookingsSqlPage.dart';
import 'package:demo_2/src/ui/coordinate_screen.dart';
import 'package:demo_2/src/ui/input_coordinate.dart';
import 'package:demo_2/src/ui/permission/permission_screen.dart';
import 'package:demo_2/src/ui/test.dart';
import 'package:demo_2/src/ui/webview/webview_khai.dart';
import 'package:demo_2/src/ui/webview/webview_kiet.dart';
import 'package:demo_2/src/ui/webview/webview_thao.dart';
import 'package:flutter/material.dart';
import 'package:demo_2/src/collections/notification_controller.dart';
import 'package:demo_2/src/ui/booking/booking_screen.dart';
import 'package:demo_2/src/ui/message/message.dart';
import 'package:demo_2/src/ui/product/product.dart';
import 'package:demo_2/src/ui/webview/ListBooking.dart';
import 'package:demo_2/src/ui/webview/test.dart';
import 'package:demo_2/src/ui/webview/test2.dart';
import 'src/ui/home/home.dart';

void main() {
  // Initialize Awesome Notifications
  NotificationController.initializeNotification();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/product': (context) => const ProductScreen(),
        '/booking': (context) => const BookingScreen(),
        '/listBookingWebview': (context) => ListBookingPage(),
        '/message': (context) => MessagePage(),
        '/test': (context) => const TestPage(),
        '/test-webview': (context) => TestWebviewPage(),
        '/test-webview2': (context) => const MyInAppBrowser(),
        '/permission': (context) => const PermissionPage(),
        '/bookings-sqite': (context) => const BookingsSqlPage(),
        '/about-us': (context) => const AboutPageWidget(),
        '/coordinate': (context) => const CoordinateListPage(),
        '/test-coordinate': (context) => const InputPage(),
        '/barcode-scanner': (context) => const BarcodePage(),
        '/test-webview-khai': (context) => const WebviewKhai(),
        '/test-webview-kiet': (context) => const WebviewKiet(),
        '/test-webview-thao': (context) => const WebviewThao(),
      },
    );
  }
}
