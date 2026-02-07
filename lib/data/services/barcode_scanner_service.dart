import 'package:mobile_scanner/mobile_scanner.dart';

/// Servicio para escanear códigos de barras
class BarcodeScannerService {
  final MobileScannerController controller;

  BarcodeScannerService({
    DetectionSpeed? detectionSpeed,
    CameraFacing? facing,
    TorchState? torchState,
  }) : controller = MobileScannerController(
          detectionSpeed: detectionSpeed ?? DetectionSpeed.normal,
          facing: facing ?? CameraFacing.back,
          torchEnabled: torchState == TorchState.on,
        );

  /// Inicia el scanner
  Future<void> start() async {
    await controller.start();
  }

  /// Detiene el scanner
  Future<void> stop() async {
    await controller.stop();
  }

  /// Alterna el flash
  Future<void> toggleTorch() async {
    await controller.toggleTorch();
  }

  /// Cambia la cámara
  Future<void> switchCamera() async {
    await controller.switchCamera();
  }

  /// Libera recursos
  void dispose() {
    controller.dispose();
  }

  /// Extrae el código de barras del capture
  String? extractBarcode(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return null;
    
    // Tomar el primer código de barras válido
    for (final barcode in barcodes) {
      if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
        return barcode.rawValue;
      }
    }
    
    return null;
  }
}
