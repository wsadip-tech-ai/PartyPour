import 'package:flutter/material.dart';

class CategoryScreen extends StatelessWidget {
  final String categoryId;
  const CategoryScreen({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Category')),
      body: Center(child: Text('Category: $categoryId')),
    );
  }
}
