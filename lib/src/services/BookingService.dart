import 'dart:convert';
import 'package:demo_2/src/collections/Booking.dart';
import 'package:http/http.dart' as http;

class BookingService {
  static const String _baseUrl = 'http://5sm.uat.byover.com:57857/5SAPI/HP';
  static const String _username = 'apidc';
  static const String _password = '444555666777';

  Future<List<Booking>> getInfoBooking(
      String userCode, String userType, String data) async {
    final headers = {
      'Func': 'DC_getInfoBooking',
      'Content-Type': 'application/json',
      'Authorization':
          // ignore: prefer_interpolation_to_compose_strings
          'Basic ' + base64Encode(utf8.encode('$_username:$_password')),
    };

    final body = jsonEncode(
        {"USER_CODE": userCode, "USER_TYPE": userType, "Data": data});

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200) {
      return parseBookings(response.body);
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<String> getRawData(
      String userCode, String userType, String data) async {
    final headers = {
      'Func': 'DC_getInfoBooking',
      'Content-Type': 'application/json',
      'Authorization':
          'Basic ' + base64Encode(utf8.encode('$_username:$_password')),
    };

    final body = jsonEncode(
        {"USER_CODE": userCode, "USER_TYPE": userType, "Data": data});

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: headers,
      body: body,
    );
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to load data');
    }
  }
}
