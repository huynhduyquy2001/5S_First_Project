import 'dart:convert';

class Booking {
  final String bookingCode;
  final String vehicleNumber;
  final String startDate;
  final String status;

  Booking({
    required this.bookingCode,
    required this.vehicleNumber,
    required this.startDate,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'bookingCode': bookingCode,
      'vehicleNumber': vehicleNumber,
      'startDate': startDate,
      'status': status,
    };
  }

  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      bookingCode: map['bookingCode'],
      vehicleNumber: map['vehicleNumber'],
      startDate: map['startDate'],
      status: map['status'],
    );
  }

  factory Booking.fromHtml(String html) {
    final RegExp bookingCodeExp =
        RegExp(r'Mã: <span class=\"code\">(.*?)<\/span>');
    final RegExp vehicleNumberExp = RegExp(r'Số xe: (.*?)<\/div>');
    final RegExp startDateExp = RegExp(r'Ngày khởi hành: (.*?)<\/div>');
    final RegExp statusExp = RegExp(r'<span class=\"status\">(.*?)<\/span>');

    return Booking(
      bookingCode: bookingCodeExp.firstMatch(html)?.group(1) ?? '',
      vehicleNumber: vehicleNumberExp.firstMatch(html)?.group(1) ?? '',
      startDate: startDateExp.firstMatch(html)?.group(1) ?? '',
      status: statusExp.firstMatch(html)?.group(1) ?? '',
    );
  }
}

List<Booking> parseBookings(String responseBody) {
  final parsed = jsonDecode(responseBody);
  final List<dynamic> data = jsonDecode(parsed['Data']);
  return data.map<Booking>((json) => Booking.fromHtml(json['RESULT'])).toList();
}
