import 'package:demo_2/src/collections/Booking.dart';
import 'package:demo_2/src/services/BookingService.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TestWebviewPage extends StatefulWidget {
  @override
  _TestWebviewPageState createState() => _TestWebviewPageState();
}

class _TestWebviewPageState extends State<TestWebviewPage> {
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
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (JavaScriptMessage message) {
          // Handle messages from JavaScript
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Received message: ${message.message}')),
          );
        },
      )
      ..loadRequest(Uri.parse('https://amethyst-karole-75.tiiny.site/'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Information'),
      ),
      body: WebViewWidget(controller: controller),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Example of sending a message to JavaScript
          controller.runJavaScript(
              'document.getElementById("flutterMessage").value = "Hello from Flutter!"; sendMessageToJavaScript();');
        },
        child: Icon(Icons.send),
      ),
    );
  }
}
