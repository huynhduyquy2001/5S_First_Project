// ignore_for_file: library_private_types_in_public_api

import 'package:demo_2/database_helper.dart';
import 'package:demo_2/src/collections/Coordinate.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class CoordinateListPage extends StatefulWidget {
  const CoordinateListPage({super.key});

  @override
  _CoordinateListPageState createState() => _CoordinateListPageState();
}

class _CoordinateListPageState extends State<CoordinateListPage> {
  final DatabaseHelper db = DatabaseHelper();
  Future<List<Coordinate>>? _coordinatesFuture;

  @override
  void initState() {
    super.initState();
    _loadCoordinates();
  }

  Future<void> _loadCoordinates() async {
    setState(() {
      _coordinatesFuture = db.getCoordinates();
    });
  }

  Future<void> _refreshCoordinates() async {
    await _loadCoordinates();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Coordinates'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshCoordinates,
        child: FutureBuilder<List<Coordinate>>(
          future: _coordinatesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No coordinates saved.'));
            } else {
              List<Coordinate> coordinates = snapshot.data!;
              return ListView.builder(
                itemCount: coordinates.length,
                itemBuilder: (context, index) {
                  Coordinate coordinate = coordinates[index];
                  DateTime timestamp = DateTime.parse(coordinate.timestamp);
                  String timeAgo = timeago.format(timestamp);

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4.0),
                    child: Card(
                      elevation: 2.0,
                      child: ListTile(
                        leading:
                            const Icon(Icons.location_on, color: Colors.blue),
                        title: Text(
                          'Latitude: ${coordinate.latitude}, Longitude: ${coordinate.longitude}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Timestamp: $timeAgo'),
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}
