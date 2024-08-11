import 'dart:convert';
import 'package:demo_2/src/collections/Product%20.dart';
import 'package:http/http.dart' as http;

class ProductService {
  static const String url = 'https://dummyjson.com/products?limit=5';

  static Future<List<Product>> fetchProducts() async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body)['products'];
      return data.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }
}
