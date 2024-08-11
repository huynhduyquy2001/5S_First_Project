// ignore_for_file: library_private_types_in_public_api, deprecated_member_use, avoid_print, unused_element

import 'dart:async';
import 'dart:io';

import 'package:demo_2/database_helper.dart';
import 'package:demo_2/src/collections/Booking.dart';
import 'package:demo_2/src/collections/Coordinate.dart';
import 'package:demo_2/src/collections/notification_controller.dart';
import 'package:demo_2/src/component/custom_drawer.dart';
import 'package:demo_2/src/component/footer.dart';
import 'package:demo_2/src/services/BookingService.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutterflow_ui/flutterflow_ui.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mssql_connection/mssql_connection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer? _timer;
  Timer? _coordinate_timer;
  final DatabaseHelper db = DatabaseHelper();

  @override
  void initState() {
    super.initState();

    //Set up a timer to fetch booking info and show notification every 30 seconds
    // _timer = Timer.periodic(const Duration(seconds: 30), (Timer timer) {
    //   getInfoBookingAndNotify();
    // });
    // _coordinate_timer =
    //     Timer.periodic(const Duration(seconds: 5), (Timer timer) {
    //   db.getCurrentLocationAndSave();
    // });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _coordinate_timer?.cancel();
    super.dispose();
  }

  int notificationId = 0; // Biến toàn cục để lưu trữ id của thông báo

  Future<void> getInfoBookingAndNotify() async {
    try {
      // Fetch raw data from the booking service
      String rawData = await BookingService().getRawData("", "", "");
      List<Booking> bookings =
          await BookingService().getInfoBooking("", "", "");
      StringBuffer bookingInfoBuffer = StringBuffer();
      for (var booking in bookings) {
        bookingInfoBuffer.writeln('Mã: ${booking.bookingCode}');
        bookingInfoBuffer.writeln('Số xe: ${booking.vehicleNumber}');
        bookingInfoBuffer.writeln('Ngày khởi hành: ${booking.startDate}');
        bookingInfoBuffer.writeln('${booking.status}\n');
      }

      String bookingInfo = bookingInfoBuffer.toString();

      // Save booking info to a text file
      await _saveToFile(bookingInfo);
      await _saveToSqlite(bookings);
      // Parse the raw data
      final parsed = jsonDecode(rawData);
      final List<dynamic> data = jsonDecode(parsed['Data']);
      String allBookingInfo = data.map((json) => json['RESULT']).join('\n');

      // Show notification with booking info
      await NotificationController.showNotification(
        title: 'Booking Information',
        body: allBookingInfo,
        payload: {'navigate': 'booking'}, // Ensure payload is set
      );
    } catch (e) {
      // Print detailed error message
      print('Error fetching booking info: $e');
    }
  }

  Future<void> _saveToFile(String data) async {
    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

      // For Android 11 (SDK 30) and above
      if (androidInfo.version.sdkInt >= 30) {
        var result = await Permission.manageExternalStorage.request();
        if (result.isGranted) {
          final directory = await getExternalStorageDirectory();
          final downloadsPath =
              '${directory?.parent.parent.parent.parent.path}/Download';
          final path = '$downloadsPath/bookings.txt';
          final file = File(path);
          // Write data to the file
          await file.writeAsString(data);
          print('Data saved to file: $path');
        } else {
          print('Permission to access storage is denied');
          return;
        }
      } else {
        // For Android versions below 11
        var status = await Permission.storage.request();
        if (status.isGranted) {
          final directory = await getExternalStorageDirectory();
          final downloadsPath =
              '${directory?.parent.parent.parent.parent.path}/Download';
          final path = '$downloadsPath/bookings.txt';
          final file = File(path);
          // Write data to the file
          await file.writeAsString(data);
          //print('Data saved to file: $path');
        } else {
          print('Permission to access storage is denied');
          return;
        }
      }
    } catch (e) {
      print('Error saving to file: $e');
    }
  }

  Future<void> _saveToDatabase(List<Booking> bookings) async {
    try {
      // Initialize the MSSQL connection
      MssqlConnection mssqlConnection = MssqlConnection.getInstance();

      // Connect to the SQL Server
      bool isConnected = await mssqlConnection.connect(
        ip: '192.168.1.40', // Replace with your SQL Server IP
        port: '1433',
        databaseName: 'Demo2_5S',
        username: 'sa',
        password: '123',
        timeoutInSeconds: 15,
      );

      if (!isConnected) {
        print('Failed to connect to the database');
        return;
      }

      // Insert each booking into the database
      for (var booking in bookings) {
        DateTime parsedDate = DateTime.parse(booking.startDate);
        String insertQuery = '''
        INSERT INTO Bookings (bookingCode, vehicleNumber, startDate, status)
        VALUES ('${booking.bookingCode}', '${booking.vehicleNumber}', '${parsedDate.toIso8601String()}', N'${booking.status}')
      ''';

        // Execute the insert query
        String insertResult = await mssqlConnection.writeData(insertQuery);
        print('Insert result for ${booking.bookingCode}: $insertResult');
      }

      // Disconnect from the database
      bool isDisconnected = await mssqlConnection.disconnect();
      print('Disconnected: $isDisconnected');
    } catch (e) {
      print('Error saving to database: $e');
    }
  }

  Future<void> _saveToSqlite(List<Booking> bookings) async {
    try {
      // Initialize the SQLite database helper
      DatabaseHelper dbHelper = DatabaseHelper();

      // Insert each booking into the database
      for (var booking in bookings) {
        await dbHelper.insertBooking(booking.toMap());
        //print('Inserted booking: ${booking.bookingCode}');
      }

      print('All bookings have been saved to the database.');
    } catch (e) {
      print('Error saving to database: $e');
    }
  }

  Future<void> getCurrentLocationAndSave() async {
    try {
      // Lấy vị trí hiện tại
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // Tạo đối tượng Coordinate
      Coordinate coordinate = Coordinate(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now().toIso8601String(),
      );

      // Lưu tọa độ vào cơ sở dữ liệu
      DatabaseHelper db = DatabaseHelper();
      await db.insertCoordinate(coordinate.toMap());

      print('Tọa độ hiện tại: ${coordinate.latitude}, ${coordinate.longitude}');
    } catch (e) {
      print('Lỗi khi lấy tọa độ: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      drawer: CustomDrawer(),
      body: SafeArea(
        top: true,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              // Generated code for this Text Widget...
              Container(
                width: MediaQuery.sizeOf(context).width * 1.0,
                decoration: const BoxDecoration(),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Flexible(
                            child: Text(
                              'Khi cần đến dịch vụ IT,\n hãy chọn Global Outsourcing.',
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    fontFamily: 'Inter',
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                    fontSize: 32.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Flexible(
                            child: Text(
                              'Với chi phí thấp và chất lượng cao,chúng tôi cam kết sẽ khiến quý khách hài lòng.',
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    fontFamily: 'Inter',
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                    fontSize: 18.0,
                                    letterSpacing: 0.0,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                0.0, 0.0, 12.0, 0.0),
                            child: FFButtonWidget(
                              onPressed: () {
                                print('Button pressed ...');
                              },
                              text: 'Portfolio',
                              icon: const Icon(
                                Icons.download,
                                size: 14.0,
                              ),
                              options: FFButtonOptions(
                                height: 40.0,
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    24.0, 0.0, 24.0, 0.0),
                                iconPadding:
                                    const EdgeInsetsDirectional.fromSTEB(
                                        0.0, 0.0, 0.0, 0.0),
                                color: const Color(0xFFF14A16),
                                textStyle: FlutterFlowTheme.of(context)
                                    .titleSmall
                                    .override(
                                      fontFamily: 'Inter',
                                      color: Colors.white,
                                      letterSpacing: 0.0,
                                    ),
                                elevation: 3.0,
                                borderSide: const BorderSide(
                                  color: Colors.transparent,
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                          ),
                          FFButtonWidget(
                            onPressed: () {
                              print('Button pressed ...');
                            },
                            text: 'Xem thêm',
                            icon: const Icon(
                              Icons.play_arrow,
                              size: 15.0,
                            ),
                            options: FFButtonOptions(
                              height: 40.0,
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  24.0, 0.0, 24.0, 0.0),
                              iconPadding: const EdgeInsetsDirectional.fromSTEB(
                                  0.0, 0.0, 0.0, 0.0),
                              color: FlutterFlowTheme.of(context)
                                  .secondaryBackground,
                              textStyle: FlutterFlowTheme.of(context)
                                  .titleSmall
                                  .override(
                                    fontFamily: 'Inter',
                                    color: const Color(0xFFF14A16),
                                    letterSpacing: 0.0,
                                  ),
                              elevation: 3.0,
                              borderSide: const BorderSide(
                                color: Colors.transparent,
                                width: 1.0,
                              ),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      thickness: 1.0,
                      indent: 12.0,
                      endIndent: 12.0,
                      color: FlutterFlowTheme.of(context).secondaryBackground,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            'TIN TỨC +',
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  fontFamily: 'Inter',
                                  color:
                                      FlutterFlowTheme.of(context).primaryText,
                                  fontSize: 24.0,
                                  letterSpacing: 0.0,
                                ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              Container(
                width: MediaQuery.sizeOf(context).width * 1.0,
                decoration: const BoxDecoration(),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.asset(
                        'assets/images/img-1.png',
                        width: double.infinity,
                        height: 520.0,
                        fit: BoxFit.cover,
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.asset(
                        'assets/images/bg-1.ac8fe3e6.png',
                        width: double.infinity,
                        height: 520.0,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
              // Generated code for this Column Widget...

              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(0, 12, 0, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Padding(
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(0, 12, 0, 12),
                      child: Text(
                        'DỊCH VỤ',
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontFamily: 'Inter',
                              color: FlutterFlowTheme.of(context).primaryText,
                              fontSize: 18,
                              letterSpacing: 0,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(0, 24, 0, 24),
                      child: Container(
                        width: MediaQuery.sizeOf(context).width,
                        decoration: const BoxDecoration(),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF14A16),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SvgPicture.network(
                                    'https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/projects/glotoss-bjzzgo/assets/z0zoxrik2w5w/icon-1.f52c889c.svg',
                                    width: 30,
                                    height: 30,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  0, 6, 0, 6),
                              child: Text(
                                'PHÁT TRIỂN ỨNG DỤNG DI ĐỘNG',
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: 'Inter',
                                      color: FlutterFlowTheme.of(context)
                                          .primaryText,
                                      fontSize: 18,
                                      letterSpacing: 0,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                            Text(
                              'Phát triển ứng dụng iOS, Android, ứng dụng lai (hybrid)',
                              textAlign: TextAlign.center,
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    fontFamily: 'Inter',
                                    letterSpacing: 0,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(0, 24, 0, 24),
                      child: Container(
                        width: MediaQuery.sizeOf(context).width,
                        decoration: const BoxDecoration(),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF14A16),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SvgPicture.network(
                                    'https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/projects/glotoss-bjzzgo/assets/5pagt2suxlrv/icon-2.59a46148.svg',
                                    width: 30,
                                    height: 30,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  0, 6, 0, 6),
                              child: Text(
                                'PHÁT TRIỂN WEB THEO YÊU CẦU',
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: 'Inter',
                                      color: FlutterFlowTheme.of(context)
                                          .primaryText,
                                      fontSize: 18,
                                      letterSpacing: 0,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                            Text(
                              'Phát triển web được tối ưu hóa theo nhu cầu khách hàng',
                              textAlign: TextAlign.center,
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    fontFamily: 'Inter',
                                    letterSpacing: 0,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(0, 24, 0, 24),
                      child: Container(
                        width: MediaQuery.sizeOf(context).width,
                        decoration: const BoxDecoration(),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF14A16),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SvgPicture.network(
                                    'https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/projects/glotoss-bjzzgo/assets/bwo7yj8s8vz0/icon-3.14cd040d.svg',
                                    width: 30,
                                    height: 30,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  0, 6, 0, 6),
                              child: Text(
                                'XỬ LÍ DỮ LIỆU',
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: 'Inter',
                                      color: FlutterFlowTheme.of(context)
                                          .primaryText,
                                      fontSize: 18,
                                      letterSpacing: 0,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                            Text(
                              'Xử lý dữ liệu cho sàn thương mại điện tử, dữ liệu huấn luyện AI',
                              textAlign: TextAlign.center,
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    fontFamily: 'Inter',
                                    letterSpacing: 0,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(0, 24, 0, 24),
                      child: Container(
                        width: MediaQuery.sizeOf(context).width,
                        decoration: const BoxDecoration(),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF14A16),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SvgPicture.network(
                                    'https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/projects/glotoss-bjzzgo/assets/jj585pruxwpg/icon-10.27c3dcd3.svg',
                                    width: 30,
                                    height: 30,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  0, 6, 0, 6),
                              child: Text(
                                'TƯ VẤN IT',
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: 'Inter',
                                      color: FlutterFlowTheme.of(context)
                                          .primaryText,
                                      fontSize: 18,
                                      letterSpacing: 0,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                            Text(
                              'Tư vấn IT mang tính chiến lược với chuyên gia giàu kinh nghiệm',
                              textAlign: TextAlign.center,
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    fontFamily: 'Inter',
                                    letterSpacing: 0,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                          12.0, 72.0, 12.0, 0.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                0.0, 12.0, 0.0, 36.0),
                            child: Text(
                              'PORTFOLIO',
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    fontFamily: 'Inter',
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                    fontSize: 18.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          Wrap(
                            spacing: 0.0,
                            runSpacing: 0.0,
                            alignment: WrapAlignment.start,
                            crossAxisAlignment: WrapCrossAlignment.start,
                            direction: Axis.horizontal,
                            runAlignment: WrapAlignment.start,
                            verticalDirection: VerticalDirection.down,
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: () {
                                  if (MediaQuery.sizeOf(context).width <
                                      kBreakpointSmall) {
                                    return MediaQuery.sizeOf(context).width;
                                  } else if (MediaQuery.sizeOf(context).width <
                                      kBreakpointMedium) {
                                    return (MediaQuery.sizeOf(context).width *
                                        0.3);
                                  } else if (MediaQuery.sizeOf(context).width <
                                      kBreakpointLarge) {
                                    return (MediaQuery.sizeOf(context).width *
                                        0.3);
                                  } else {
                                    return (MediaQuery.sizeOf(context).width *
                                        0.3);
                                  }
                                }(),
                                decoration: const BoxDecoration(),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Image.network(
                                    'https://www.glotoss.com/asset/images/balaan.png',
                                    fit: BoxFit.contain,
                                    alignment: const Alignment(1.0, 0.0),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: () {
                                  if (MediaQuery.sizeOf(context).width <
                                      kBreakpointSmall) {
                                    return MediaQuery.sizeOf(context).width;
                                  } else if (MediaQuery.sizeOf(context).width <
                                      kBreakpointMedium) {
                                    return (MediaQuery.sizeOf(context).width *
                                        0.3);
                                  } else if (MediaQuery.sizeOf(context).width <
                                      kBreakpointLarge) {
                                    return (MediaQuery.sizeOf(context).width *
                                        0.3);
                                  } else {
                                    return (MediaQuery.sizeOf(context).width *
                                        0.3);
                                  }
                                }(),
                                child: Stack(
                                  alignment:
                                      const AlignmentDirectional(0.0, 0.0),
                                  children: [
                                    Align(
                                      alignment: const AlignmentDirectional(
                                          -2.0, -1.0),
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        child: Image.network(
                                          'https://www.glotoss.com/_next/static/media/bg-4.943d1a14.png',
                                          width: () {
                                            if (MediaQuery.sizeOf(context)
                                                    .width <
                                                kBreakpointSmall) {
                                              return MediaQuery.sizeOf(context)
                                                  .width;
                                            } else if (MediaQuery.sizeOf(
                                                        context)
                                                    .width <
                                                kBreakpointMedium) {
                                              return (MediaQuery.sizeOf(context)
                                                      .width *
                                                  0.45);
                                            } else if (MediaQuery.sizeOf(
                                                        context)
                                                    .width <
                                                kBreakpointLarge) {
                                              return (MediaQuery.sizeOf(context)
                                                      .width *
                                                  0.45);
                                            } else {
                                              return (MediaQuery.sizeOf(context)
                                                      .width *
                                                  0.45);
                                            }
                                          }(),
                                          height: 313.0,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      decoration: const BoxDecoration(),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsetsDirectional
                                                .fromSTEB(0.0, 0.0, 0.0, 12.0),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsetsDirectional
                                                          .fromSTEB(
                                                          0.0, 6.0, 0.0, 6.0),
                                                  child: Text(
                                                    'Xử lý dữ liệu',
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .override(
                                                          fontFamily: 'Inter',
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .primaryText,
                                                          fontSize: 18.0,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsetsDirectional
                                                .fromSTEB(0.0, 12.0, 0.0, 12.0),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsetsDirectional
                                                          .fromSTEB(
                                                          0.0, 6.0, 0.0, 6.0),
                                                  child: Text(
                                                    'Balance',
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .override(
                                                          fontFamily: 'Inter',
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .secondaryText,
                                                          fontSize: 18.0,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              Flexible(
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsetsDirectional
                                                          .fromSTEB(
                                                          0.0, 12.0, 0.0, 12.0),
                                                  child: Text(
                                                    'Tư vấn IT mang tính chiến lược với chuyên gia giàu kinh nghiệm',
                                                    textAlign: TextAlign.start,
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .override(
                                                          fontFamily: 'Inter',
                                                          letterSpacing: 0.0,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Padding(
                                            padding: const EdgeInsetsDirectional
                                                .fromSTEB(0.0, 12.0, 0.0, 4.0),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                FFButtonWidget(
                                                  onPressed: () {
                                                    print('Button pressed ...');
                                                  },
                                                  text:
                                                      'Xem thêm trên Portfolio',
                                                  icon: const FaIcon(
                                                    FontAwesomeIcons
                                                        .externalLinkAlt,
                                                  ),
                                                  options: FFButtonOptions(
                                                    height: 53.0,
                                                    padding:
                                                        const EdgeInsetsDirectional
                                                            .fromSTEB(24.0, 0.0,
                                                            24.0, 0.0),
                                                    iconPadding:
                                                        const EdgeInsetsDirectional
                                                            .fromSTEB(
                                                            0.0, 0.0, 0.0, 0.0),
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .secondaryBackground,
                                                    textStyle: FlutterFlowTheme
                                                            .of(context)
                                                        .titleSmall
                                                        .override(
                                                          fontFamily: 'Inter',
                                                          color: const Color(
                                                              0xFFF14A16),
                                                          letterSpacing: 0.0,
                                                        ),
                                                    borderSide:
                                                        const BorderSide(
                                                      color: Color(0xFFF14A16),
                                                      width: 1.0,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8.0),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              Stack(
                children: [
                  Align(
                    alignment: const AlignmentDirectional(-1.0, -1.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        'https://www.glotoss.com/_next/static/media/bg-4.943d1a14.png',
                        width: 300.0,
                        height: 516.0,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                        12.0, 72.0, 12.0, 0.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.network(
                            'https://www.glotoss.com/asset/images/cust3.png',
                            width: 400.0,
                            height: 200.0,
                            fit: BoxFit.contain,
                          ),
                        ),
                        Stack(
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                      0.0, 12.0, 0.0, 0.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsetsDirectional
                                            .fromSTEB(0.0, 6.0, 0.0, 6.0),
                                        child: Text(
                                          'JOONGANG CONTROL Homepage',
                                          textAlign: TextAlign.center,
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                fontFamily: 'Inter',
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primaryText,
                                                fontSize: 18.0,
                                                letterSpacing: 0.0,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                      0.0, 0.0, 0.0, 12.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Flexible(
                                        child: Padding(
                                          padding: const EdgeInsetsDirectional
                                              .fromSTEB(0.0, 6.0, 0.0, 6.0),
                                          child: Text(
                                            'Lee Ja-seung, Người quản lý Nhóm Chiến lược & Lập kế hoạch',
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  fontFamily: 'Inter',
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondaryText,
                                                  fontSize: 18.0,
                                                  letterSpacing: 0.0,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  'Trước khi chuyển công ty bảo trì bên mình lo nhiều nhưng giờ thấy phản hồi nhanh nhờ giao tiếp suôn sẻ và thực hiện hầu hết mong muốn với kỹ thuật chuyên môn. Nhờ điều đó bên mình có thể duy trì và phân phối trang chủ một cách ổn định trong thời gian ngắn.',
                                  textAlign: TextAlign.start,
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        fontFamily: 'Inter',
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.normal,
                                      ),
                                ),
                                Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                      0.0, 4.0, 0.0, 4.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      RatingBarIndicator(
                                        itemBuilder: (context, index) =>
                                            const Icon(
                                          Icons.star,
                                          color: Color(0xFFEBDB22),
                                        ),
                                        direction: Axis.horizontal,
                                        rating: 5.0,
                                        unratedColor:
                                            FlutterFlowTheme.of(context)
                                                .secondaryText,
                                        itemCount: 5,
                                        itemSize: 24.0,
                                      ),
                                      Text(
                                        '4.8',
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              fontFamily: 'Inter',
                                              fontSize: 18.0,
                                              letterSpacing: 0.0,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                      0.0, 12.0, 0.0, 12.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Material(
                                        color: Colors.transparent,
                                        elevation: 3.0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(24.0),
                                        ),
                                        child: Container(
                                          width: 100.0,
                                          height: 48.0,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFEEDE7),
                                            borderRadius:
                                                BorderRadius.circular(24.0),
                                            border: Border.all(
                                              color: const Color(0xFFF14A16),
                                              width: 1.0,
                                            ),
                                          ),
                                          alignment: const AlignmentDirectional(
                                              0.0, 0.0),
                                          child: Text(
                                            'Mã nguồn mở',
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  fontFamily: 'Inter',
                                                  color:
                                                      const Color(0xFFF14A16),
                                                  letterSpacing: 0.0,
                                                ),
                                          ),
                                        ),
                                      ),
                                      Material(
                                        color: Colors.transparent,
                                        elevation: 3.0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(24.0),
                                        ),
                                        child: Container(
                                          width: 100.0,
                                          height: 48.0,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFEEDE7),
                                            borderRadius:
                                                BorderRadius.circular(24.0),
                                            border: Border.all(
                                              color: const Color(0xFFF14A16),
                                              width: 1.0,
                                            ),
                                          ),
                                          alignment: const AlignmentDirectional(
                                              0.0, 0.0),
                                          child: Text(
                                            'Giảm chi phí',
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  fontFamily: 'Inter',
                                                  color:
                                                      const Color(0xFFF14A16),
                                                  letterSpacing: 0.0,
                                                ),
                                          ),
                                        ),
                                      ),
                                      Material(
                                        color: Colors.transparent,
                                        elevation: 3.0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(24.0),
                                        ),
                                        child: Container(
                                          width: 100.0,
                                          height: 48.0,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFEEDE7),
                                            borderRadius:
                                                BorderRadius.circular(24.0),
                                            border: Border.all(
                                              color: const Color(0xFFF14A16),
                                              width: 1.0,
                                            ),
                                          ),
                                          alignment: const AlignmentDirectional(
                                              0.0, 0.0),
                                          child: Text(
                                            'NestJS',
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  fontFamily: 'Inter',
                                                  color:
                                                      const Color(0xFFF14A16),
                                                  letterSpacing: 0.0,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ].divide(const SizedBox(width: 10.0)),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                      0.0, 12.0, 0.0, 12.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      FFButtonWidget(
                                        onPressed: () {
                                          print('Button pressed ...');
                                        },
                                        text: 'Xem thêm dự án',
                                        icon: const FaIcon(
                                          FontAwesomeIcons.externalLinkAlt,
                                        ),
                                        options: FFButtonOptions(
                                          height: 53.0,
                                          padding: const EdgeInsetsDirectional
                                              .fromSTEB(24.0, 0.0, 24.0, 0.0),
                                          iconPadding:
                                              const EdgeInsetsDirectional
                                                  .fromSTEB(0.0, 0.0, 0.0, 0.0),
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryBackground,
                                          textStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleSmall
                                                  .override(
                                                    fontFamily: 'Inter',
                                                    color:
                                                        const Color(0xFFF14A16),
                                                    letterSpacing: 0.0,
                                                  ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFF14A16),
                                            width: 1.0,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding:
                    const EdgeInsetsDirectional.fromSTEB(0.0, 48.0, 0.0, 24.0),
                child: Text(
                  'KHÁNG HÀNG CỦA CHÚNG TÔI',
                  textAlign: TextAlign.center,
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Inter',
                        color: FlutterFlowTheme.of(context).primaryText,
                        fontSize: 18.0,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).secondaryBackground,
                  ),
                  child: GridView(
                    padding: EdgeInsets.zero,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: () {
                        if (MediaQuery.sizeOf(context).width <
                            kBreakpointSmall) {
                          return 2;
                        } else if (MediaQuery.sizeOf(context).width <
                            kBreakpointMedium) {
                          return 3;
                        } else if (MediaQuery.sizeOf(context).width <
                            kBreakpointLarge) {
                          return 4;
                        } else {
                          return 4;
                        }
                      }(),
                      crossAxisSpacing: 10.0,
                      mainAxisSpacing: 10.0,
                      childAspectRatio: 1.6,
                    ),
                    primary: false,
                    shrinkWrap: true,
                    scrollDirection: Axis.vertical,
                    children: [
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                            0.0, 0.0, 0.0, 1.0),
                        child: Material(
                          color: Colors.transparent,
                          elevation: 3.0,
                          child: Container(
                            width: 100.0,
                            height: 100.0,
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context)
                                  .secondaryBackground,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(22.0),
                              child: SvgPicture.network(
                                'https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/projects/glotoss-bjzzgo/assets/9yowqh6qo2e9/client-logo-07.svg',
                                width: 300.0,
                                height: 200.0,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                            0.0, 0.0, 0.0, 1.0),
                        child: Material(
                          color: Colors.transparent,
                          elevation: 3.0,
                          child: Container(
                            width: 100.0,
                            height: 100.0,
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context)
                                  .secondaryBackground,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: SvgPicture.network(
                                'https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/projects/glotoss-bjzzgo/assets/gxvzw8utxj5g/chilsung.svg',
                                width: 300.0,
                                height: 200.0,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                            0.0, 0.0, 0.0, 1.0),
                        child: Material(
                          color: Colors.transparent,
                          elevation: 3.0,
                          child: Container(
                            width: 100.0,
                            height: 100.0,
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context)
                                  .secondaryBackground,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: SvgPicture.network(
                                'https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/projects/glotoss-bjzzgo/assets/27bf8faixtpe/client-logo-01.svg',
                                width: 300.0,
                                height: 200.0,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                            0.0, 0.0, 0.0, 1.0),
                        child: Material(
                          color: Colors.transparent,
                          elevation: 3.0,
                          child: Container(
                            width: 100.0,
                            height: 100.0,
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context)
                                  .secondaryBackground,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: SvgPicture.network(
                                'https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/projects/glotoss-bjzzgo/assets/ksbwknut0iby/client-logo-02.svg',
                                width: 300.0,
                                height: 200.0,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const FooterWidget()
            ],
          ),
        ),
      ),
    );
  }
}
