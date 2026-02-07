import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/product_provider.dart';
import '../providers/auth_provider.dart';

class ScannerScreen extends StatefulWidget {
  final bool showBottomNav;

  const ScannerScreen({super.key, this.showBottomNav = false});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  MobileScannerController? _controller;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first.rawValue;
    if (barcode == null || barcode.isEmpty) return;

    setState(() => _isProcessing = true);

    // Obtener providers antes del async gap
    final authProvider = context.read<AuthProvider>();
    final productProvider = context.read<ProductProvider>();

    // Detener la cámara
    await _controller?.stop();

    // Escanear producto
    await productProvider.scanBarcode(barcode, authProvider.currentUser!.id);

    setState(() => _isProcessing = false);

    if (!mounted) return;

    // Mostrar resultado
    if (productProvider.scannedProduct != null) {
      _showProductDialog(productProvider);
    } else {
      _showErrorDialog(productProvider.error ?? 'Producto no encontrado');
    }
  }

  void _showProductDialog(ProductProvider provider) {
    final product = provider.scannedProduct!;
    final alreadyExists = provider.isProductAlreadySaved(product.barcode);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(product.name),
            if (alreadyExists)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Ya tienes este producto',
                  style: TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (product.imageUrl.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: product.imageUrl,
                  height: 150,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const SizedBox(
                    height: 150,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => const Icon(Icons.image_not_supported, size: 100),
                ),
              const SizedBox(height: 12),
              Text('Marca: ${product.brand}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Código: ${product.barcode}'),
              if (product.category.isNotEmpty) Text('Categoría: ${product.category}'),
              const Divider(height: 20),
              const Text('Información Nutricional (por 100g):', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildNutritionalRow('Calorías', '${product.nutritionalInfo.calories.toStringAsFixed(1)} kcal'),
              _buildNutritionalRow('Proteínas', '${product.nutritionalInfo.protein.toStringAsFixed(1)}g'),
              _buildNutritionalRow('Carbohidratos', '${product.nutritionalInfo.carbohydrates.toStringAsFixed(1)}g'),
              _buildNutritionalRow('Grasas', '${product.nutritionalInfo.fat.toStringAsFixed(1)}g'),
              if (product.nutritionalInfo.fiber > 0)
                _buildNutritionalRow('Fibra', '${product.nutritionalInfo.fiber.toStringAsFixed(1)}g'),
              if (product.nutritionalInfo.sugar > 0)
                _buildNutritionalRow('Azúcares', '${product.nutritionalInfo.sugar.toStringAsFixed(1)}g'),
              if (product.nutritionalInfo.sodium > 0)
                _buildNutritionalRow('Sodio', '${product.nutritionalInfo.sodium.toStringAsFixed(1)}g'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              provider.clearScannedProduct();
              Navigator.of(context).pop(); // Volver a la lista de productos
            },
            child: Text(alreadyExists ? 'Cerrar' : 'Cancelar'),
          ),
          if (!alreadyExists)
            ElevatedButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                final authProvider = context.read<AuthProvider>();
                await provider.createProductFromScanned(authProvider.currentUser!.id);
                if (!mounted) return;
                Navigator.of(context).pop(); // Volver a la lista de productos
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Producto guardado')),
                );
              },
              child: const Text('Guardar'),
            ),
        ],
      ),
    );
  }

  Widget _buildNutritionalRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<ProductProvider>().clearError();
              Navigator.of(context).pop(); // Volver a la lista de productos
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showBottomNav
          ? null
          : AppBar(
              title: const Text('Escanear Producto'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.flash_on),
                  onPressed: () => _controller?.toggleTorch(),
                ),
                IconButton(
                  icon: const Icon(Icons.flip_camera_ios),
                  onPressed: () => _controller?.switchCamera(),
                ),
              ],
            ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // Overlay con área de escaneo
          Positioned.fill(
            child: CustomPaint(
              painter: _ScannerOverlayPainter(),
            ),
          ),
          // Instrucciones
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black54,
              child: const Text(
                'Coloca el código de barras dentro del marco',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
          // Indicador de carga
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    final scanArea = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.7,
      height: size.height * 0.4,
    );

    canvas.drawPath(
      Path()
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
        ..addRect(scanArea)
        ..fillType = PathFillType.evenOdd,
      paint,
    );

    // Dibujar borde del área de escaneo
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRect(scanArea, borderPaint);

    // Dibujar esquinas
    final cornerPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;

    const cornerLength = 30.0;

    // Esquina superior izquierda
    canvas.drawLine(
      scanArea.topLeft,
      scanArea.topLeft + const Offset(cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scanArea.topLeft,
      scanArea.topLeft + const Offset(0, cornerLength),
      cornerPaint,
    );

    // Esquina superior derecha
    canvas.drawLine(
      scanArea.topRight,
      scanArea.topRight + const Offset(-cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scanArea.topRight,
      scanArea.topRight + const Offset(0, cornerLength),
      cornerPaint,
    );

    // Esquina inferior izquierda
    canvas.drawLine(
      scanArea.bottomLeft,
      scanArea.bottomLeft + const Offset(cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scanArea.bottomLeft,
      scanArea.bottomLeft + const Offset(0, -cornerLength),
      cornerPaint,
    );

    // Esquina inferior derecha
    canvas.drawLine(
      scanArea.bottomRight,
      scanArea.bottomRight + const Offset(-cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scanArea.bottomRight,
      scanArea.bottomRight + const Offset(0, -cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
