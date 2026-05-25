import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../services/api_service.dart';
import 'product_screen.dart';

class ProductDeepLinkScreen extends StatefulWidget {
  final String productId;

  const ProductDeepLinkScreen({
    super.key,
    required this.productId,
  });

  @override
  State<ProductDeepLinkScreen> createState() => _ProductDeepLinkScreenState();
}

class _ProductDeepLinkScreenState extends State<ProductDeepLinkScreen> {
  late Future<Product> _productFuture;

  @override
  void initState() {
    super.initState();
    _productFuture = context.read<ApiService>().getProductById(widget.productId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Product>(
      future: _productFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              foregroundColor: Colors.black87,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 56,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Produto nao encontrado',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Esse link pode ter expirado ou o produto foi removido.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/home',
                          (route) => false,
                        );
                      },
                      child: const Text('Ver cardapio'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return ProductScreen(product: snapshot.data!);
      },
    );
  }
}
