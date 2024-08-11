// ignore_for_file: unused_local_variable

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';

class BarcodePage extends StatefulWidget {
  const BarcodePage({super.key});

  @override
  _BarcodePageState createState() => _BarcodePageState();
}

class _BarcodePageState extends State<BarcodePage> {
  InAppWebViewController? webViewController;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    if (await Permission.camera.isDenied) {
      await Permission.camera.request();
    }

    if (await Permission.storage.isDenied) {
      await Permission.storage.request();
    }
  }

  void _injectJavaScript(InAppWebViewController controller) {
    controller.evaluateJavascript(source: '''
      window.Android = {
        nextScreen: function(screenId) {
          window.flutter_inappwebview.callHandler('nextScreen', screenId);
        }
      };
    ''').then((result) {
      print("JavaScript injected successfully.");
    }).catchError((error) {
      print("Error injecting JavaScript: $error");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test'),
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(
            url: Uri.parse(
                "http://fpits.5svisions.com:3003/fsmdls/Survey/Survey.aspx?ProgramCD=2&Customercode=VNC0019604&USER_CODE=VNS9026&type=1")),
        onWebViewCreated: (controller) {
          webViewController = controller;
          _injectJavaScript(controller);

          // Set up JavaScript handlers
          controller.addJavaScriptHandler(
              handlerName: 'nextScreen',
              callback: (args) {
                print('Received call from JavaScript:');
                String screenId = args[0];
                _nextScreen(screenId);
              });
        },
        onLoadStart: (controller, url) {
          setState(() {
            print("Started loading: $url");
          });
        },
        onLoadStop: (controller, url) {
          setState(() {
            print("Stopped loading: $url");
          });
          _injectJavaScript(controller); // Inject JavaScript on load stop
        },
        onUpdateVisitedHistory: (controller, url, androidIsReload) {
          setState(() {
            print("Visited URL: $url");
          });
          _injectJavaScript(controller); // Inject JavaScript on URL change
        },
      ),
    );
  }

  Future<void> _nextScreen(String screenId) async {
    String barcodeScanRes;
    print('hello: $screenId');
    if (screenId == '3') {
      try {
        barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          "#ff6666", // scanning line color
          "Cancel", // cancel button text
          true, // show flash icon
          ScanMode.BARCODE,
        );
        print('Barcode scan result: $barcodeScanRes');
        if (!mounted) return;

        // Call the JavaScript function directly with the base64 string
        String jsString = '''
        FOCamera_Get_Barcode_Image("$barcodeScanRes");
      ''';
        // Execute the JavaScript code and log the result
        webViewController?.evaluateJavascript(source: jsString).then((result) {
          print("JavaScript executed successfully.");
        }).catchError((error) {
          print("Failed to execute JavaScript: $error");
        });

        // Hiển thị thông báo với kết quả barcodeScanRes
        _showBarcodeDialog(context, barcodeScanRes);
      } catch (e) {
        print('Failed to get barcode: $e');
      }
    } else {
      // Assume the data is a URL to a file to be downloaded
      await _downloadFile(screenId);
    }
  }

  Future<void> _downloadFile(String url) async {
    try {
      Directory? directory = await getExternalStorageDirectory();
      if (directory == null) {
        throw Exception("External storage directory not found");
      }

      final downloadsPath =
          '${directory.parent.parent.parent.parent.path}/Download';
      Directory downloadDir = Directory(downloadsPath);

      // Create the Download directory if it doesn't exist
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      String fileName = url.split('/').last;
      String path = '$downloadsPath/$fileName';
      File file = File(path);

      Dio dio = Dio();
      await dio.download(url, path);
      // Hiển thị snackbar thông báo thành công
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File downloaded to: $path'),
        ),
      );
      print('File downloaded to: $path');
    } catch (e) {
      print('Error downloading file: $e');
    }
  }

  void _showBarcodeDialog(BuildContext context, String barcode) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Barcode Result'),
          content: Text(barcode),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
