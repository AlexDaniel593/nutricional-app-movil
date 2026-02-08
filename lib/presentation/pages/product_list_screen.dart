import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/product_provider.dart';
import '../providers/auth_provider.dart';
import '../../domain/entities/product.dart';
import 'scanner_screen.dart';
import 'product_detail_screen.dart';

class ProductListScreen extends StatefulWidget {
  final bool showBottomNav;

  const ProductListScreen({super.key, this.showBottomNav = false});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProducts();
    });
  }

  Future<void> _loadProducts() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUser != null) {
      await context.read<ProductProvider>().loadProducts(userId: authProvider.currentUser!.id);
    }
  }

  void _deleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: Text('¿Estás seguro de eliminar "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await context.read<ProductProvider>().deleteProduct(product.id);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Producto eliminado')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();

    return Scaffold(
      appBar: widget.showBottomNav
          ? null
          : AppBar(
              title: const Text('Mis Productos'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ScannerScreen()),
                    );
                  },
                ),
              ],
            ),
      body: productProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : productProvider.products.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No hay productos', style: TextStyle(fontSize: 18, color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ScannerScreen()),
                          );
                        },
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Escanear Producto'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProducts,
                  child: ListView.builder(
                    itemCount: productProvider.products.length,
                    itemBuilder: (ctx, index) {
                      final product = productProvider.products[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ProductDetailScreen(product: product),
                              ),
                            );
                          },
                          leading: product.imageUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: product.imageUrl,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => const Icon(Icons.image_not_supported),
                                )
                              : const Icon(Icons.inventory_2, size: 40),
                          title: Text(
                            product.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(product.brand),
                              Text(
                                'Código: ${product.barcode}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              Text(
                                '${product.nutritionalInfo.calories.toStringAsFixed(0)} kcal | '
                                'P: ${product.nutritionalInfo.protein.toStringAsFixed(1)}g | '
                                'C: ${product.nutritionalInfo.carbohydrates.toStringAsFixed(1)}g | '
                                'G: ${product.nutritionalInfo.fat.toStringAsFixed(1)}g',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteProduct(product),
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
