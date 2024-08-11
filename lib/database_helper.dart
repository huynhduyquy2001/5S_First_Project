import 'package:demo_2/src/collections/Booking.dart';
import 'package:demo_2/src/collections/Coordinate.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    print('location:$documentsDirectory');
    String path = join(documentsDirectory.path, 'bookings.db');
    return await openDatabase(
      path,
      version: 2, // Tăng phiên bản cơ sở dữ liệu lên 2
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE Bookings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bookingCode TEXT,
        vehicleNumber TEXT,
        startDate TEXT,
        status TEXT
      )
      ''');

    await db.execute('''
      CREATE TABLE Coordinates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        latitude REAL,
        longitude REAL,
        timestamp TEXT
      )
      ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Thêm bảng Coordinates nếu phiên bản cơ sở dữ liệu cũ là 1
      await db.execute('''
        CREATE TABLE Coordinates (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          latitude REAL,
          longitude REAL,
          timestamp TEXT
        )
        ''');
    }
  }

  Future<void> insertBooking(Map<String, dynamic> booking) async {
    final db = await database;
    await db.insert(
      'Bookings',
      booking,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Booking>> getBookings() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('Bookings');

    return List.generate(maps.length, (i) {
      return Booking.fromMap(maps[i]);
    });
  }

  Future<void> insertCoordinate(Map<String, dynamic> coordinate) async {
    final db = await database;
    await db.insert(
      'Coordinates',
      coordinate,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Coordinate>> getCoordinates() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Coordinates',
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      return Coordinate.fromMap(maps[i]);
    });
  }

  Future<void> getCurrentLocationAndSave() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      Coordinate coordinate = Coordinate(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now().toIso8601String(),
      );

      await insertCoordinate(coordinate.toMap());

      if (kDebugMode) {
        print(
            'Tọa độ hiện tại: ${coordinate.latitude}, ${coordinate.longitude}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi lấy tọa độ: $e');
      }
    }
  }
}
