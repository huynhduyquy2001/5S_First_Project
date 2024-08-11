// ignore_for_file: library_private_types_in_public_api

import 'package:demo_2/database_helper.dart';
import 'package:demo_2/src/collections/Booking.dart';
import 'package:flutter/material.dart';

class BookingsSqlPage extends StatefulWidget {
  const BookingsSqlPage({super.key});

  @override
  _BookingsSqlPageState createState() => _BookingsSqlPageState();
}

class _BookingsSqlPageState extends State<BookingsSqlPage> {
  late Future<List<Booking>> futureBookings;

  @override
  void initState() {
    super.initState();
    futureBookings = DatabaseHelper().getBookings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookings'),
      ),
      body: FutureBuilder<List<Booking>>(
        future: futureBookings,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No bookings found.'));
          } else {
            final bookings = snapshot.data!;
            return ListView.builder(
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final booking = bookings[index];
                return ListTile(
                  title: Text(booking.bookingCode),
                  subtitle: Text(
                      'Vehicle: ${booking.vehicleNumber}, Date: ${booking.startDate}, Status: ${booking.status}'),
                );
              },
            );
          }
        },
      ),
    );
  }
}
