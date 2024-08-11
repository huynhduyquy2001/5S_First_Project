// ignore_for_file: use_key_in_widget_constructors, library_private_types_in_public_api

import 'package:demo_2/src/collections/Booking.dart';
import 'package:demo_2/src/services/BookingService.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ListBookingPage extends StatefulWidget {
  @override
  _ListBookingPageState createState() => _ListBookingPageState();
}

class _ListBookingPageState extends State<ListBookingPage> {
  late Future<List<Booking>> futureData;
  late WebViewController controller;
  @override
  void initState() {
    super.initState();
    futureData = BookingService().getInfoBooking("", "", "");
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onHttpError: (HttpResponseError error) {},
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://www.youtube.com/')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(
          'http://5sm.uat.byover.com:57857/fsmdls/DC/CustomerBooking.aspx'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Information'),
      ),
      body: WebViewWidget(controller: controller),
    );
  }
}
