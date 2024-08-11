// ignore_for_file: library_private_types_in_public_api, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebviewKhai extends StatefulWidget {
  const WebviewKhai({super.key});

  @override
  _WebviewKhaiState createState() => _WebviewKhaiState();
}

class _WebviewKhaiState extends State<WebviewKhai> {
  InAppWebViewController? webViewController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Khải's InAppWebView Example"),
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(
            url: Uri.parse("https://amethyst-karole-75.tiiny.site/")),
        onWebViewCreated: (controller) {
          webViewController = controller;

          // Set up JavaScript handlers
          controller.addJavaScriptHandler(
              handlerName: 'sendData',
              callback: (args) {
                // Here you can handle the data received from HTML
                String data = args[0];
                print("Data received from HTML: $data");
                _showDataReceivedPopup(data);

                // Optionally send a response back to the HTML
                controller.evaluateJavascript(
                    source: "receiveFromFlutter('Data received: $data')");
              });
        },
        onLoadStart: (controller, url) {
          setState(() {
            print("started loading $url");
          });
        },
        onLoadStop: (controller, url) {
          setState(() {
            print("stopped loading $url");
          });
        },
      ),
    );
  }

  // Function to show a popup dialog
  void _showDataReceivedPopup(String data) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Data Received'),
          content: Text('Data from HTML: $data'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
