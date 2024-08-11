// import 'package:demo_2/src/collections/Booking.dart';
// import 'package:demo_2/src/services/BookingService.dart';
// import 'package:flutter/material.dart';

// class BookingScreen extends StatefulWidget {
//   @override
//   _BookingScreenState createState() => _BookingScreenState();
// }

// class _BookingScreenState extends State<BookingScreen> {
//   late Future<List<Booking>> futureData;

//   @override
//   void initState() {
//     super.initState();
//     futureData = BookingService().getInfoBooking("", "", "");
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Booking Information'),
//       ),
//       body: FutureBuilder<List<Booking>>(
//         future: futureData,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           } else if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//             return const Center(child: Text('No bookings found'));
//           }

// ignore_for_file: library_private_types_in_public_api

//           // Render dữ liệu từ snapshot.data
//           final data = snapshot.data!;
//           return ListView.builder(
//             itemCount: data.length,
//             itemBuilder: (context, index) {
//               final booking = data[index];
//               return Card(
//                 margin:
//                     const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
//                 child: Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text('Mã: ${booking.bookingCode}',
//                           style: const TextStyle(fontWeight: FontWeight.bold)),
//                       Text('Số xe: ${booking.vehicleNumber}'),
//                       Text('Ngày khởi hành: ${booking.startDate}'),
//                       Text('Trạng thái: ${booking.status}'),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }
import 'package:demo_2/src/services/BookingService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'dart:convert';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  late Future<List<Map<String, String>>> futureData;

  @override
  void initState() {
    super.initState();
    futureData = _fetchAndParseBookings();
  }

  Future<List<Map<String, String>>> _fetchAndParseBookings() async {
    try {
      String rawData = await BookingService().getRawData("", "", "");
      final parsed = jsonDecode(rawData);
      final List<dynamic> data = jsonDecode(parsed['Data']);
      return data
          .map<Map<String, String>>((json) => {'RESULT': json['RESULT']})
          .toList();
    } catch (e) {
      throw Exception('Failed to load and parse bookings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Information'),
      ),
      body: FutureBuilder<List<Map<String, String>>>(
        future: futureData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No bookings found'));
          }

          // Render dữ liệu từ snapshot.data
          final data = snapshot.data!;
          String allBookingHtml =
              data.map((booking) => booking['RESULT']).join('\n');

          return SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(8.0),
              child: Html(data: allBookingHtml),
            ),
          );
        },
      ),
    );
  }
}
