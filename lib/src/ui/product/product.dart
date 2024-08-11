// ignore_for_file: library_private_types_in_public_api

import 'package:demo_2/src/collections/Product%20.dart';
import 'package:demo_2/src/services/ProductService%20.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  _ProductScreenState createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  late Future<List<Product>> futureProducts;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    futureProducts = ProductService.fetchProducts();
    futureProducts.then((products) {
      setState(() {
        _products = products;
      });
      _addProducts(products);
    });
  }

  void _addProducts(List<Product> products) {
    Future ft = Future(() {});
    for (int i = 0; i < products.length; i++) {
      ft = ft.then((_) {
        return Future.delayed(const Duration(milliseconds: 100), () {
          if (_listKey.currentState != null) {
            _listKey.currentState?.insertItem(i);
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product List'),
      ),
      body: FutureBuilder<List<Product>>(
        future: futureProducts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No products found'));
          }

          return AnimatedList(
            key: _listKey,
            initialItemCount: _products.length,
            itemBuilder: (context, index, animation) {
              if (index < _products.length) {
                return _buildItem(_products[index], animation);
              } else {
                return Container(); // Avoid returning null
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildItem(Product product, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: const Offset(0, 0),
            ).animate(animation),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.network(
                product.thumbnail,
                fit: BoxFit.cover,
                width: 80,
                height: 80,
              ),
              const SizedBox(
                  width: 16.0), // Add some space between the image and text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.title,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Hãng: ${product.category}'),
                    Text('Giá: ${product.price.toStringAsFixed(2)} VND'),
                    Text(
                        'Giảm giá: ${product.discountPercentage.toStringAsFixed(2)}%'),
                    Row(
                      children: [
                        const Text('Đánh giá: '),
                        RatingBarIndicator(
                          rating: product.rating,
                          itemBuilder: (context, index) => const Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          itemCount: 5,
                          itemSize: 20.0,
                          direction: Axis.horizontal,
                        ),
                      ],
                    ),
                    Text('Kho: ${product.stock}'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
