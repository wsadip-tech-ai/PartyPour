import 'package:flutter/material.dart';

class ProductListScreen extends StatelessWidget {
  final String subcategoryId;
  const ProductListScreen({super.key, required this.subcategoryId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: Center(child: Text('Subcategory: $subcategoryId')),
    );
  }
}
