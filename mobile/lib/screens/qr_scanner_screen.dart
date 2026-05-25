import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _hasScanned = false;
  bool _isRetrying = false;
  late final MobileScannerController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0F172A),
                    Color(0xFF050816),
                  ],
                ),
              ),
            ),
          ),

          // Câmera ocupando toda a tela
          Positioned.fill(
            child: MobileScanner(
              key: const ValueKey('mobile_scanner'),
              controller: _controller,
              fit: BoxFit.cover,
              placeholderBuilder: (context, child) => _buildFallbackState(
                context,
                title: 'Preparando a câmera',
                message:
                    'Estamos inicializando o scanner para abrir a câmera com segurança.',
                icon: Icons.document_scanner_outlined,
                actionLabel: null,
                onAction: null,
              ),
              errorBuilder: (context, error, child) => _buildFallbackState(
                context,
                title: 'Não foi possível abrir a câmera',
                message: error.errorCode ==
                        MobileScannerErrorCode.permissionDenied
                    ? 'A permissão da câmera foi negada. Ative-a nas configurações do aparelho para continuar.'
                    : (error.errorDetails?.message ??
                        'Tente novamente em alguns segundos.'),
                icon: Icons.no_photography_outlined,
                actionLabel: 'Tentar novamente',
                onAction: _retryCamera,
              ),
              onDetect: (capture) {
                if (_hasScanned || capture.barcodes.isEmpty) return;
                final barcode = capture.barcodes.first;
                final value = barcode.rawValue ?? barcode.displayValue;
                if (value == null || value.isEmpty) return;

                _hasScanned = true;
                Navigator.of(context).pop(value);
              },
            ),
          ),

          // Overlay com recorte arredondado consistente
          Positioned.fill(
            child: IgnorePointer(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final scanSize = math.min(constraints.maxWidth * 0.78, 340.0);
                  final holeOffset = Offset(
                    (constraints.maxWidth - scanSize) / 2,
                    (constraints.maxHeight - scanSize) / 2,
                  );

                  return CustomPaint(
                    painter: _ScannerOverlayPainter(
                      holeOffset: holeOffset,
                      holeSize: Size(scanSize, scanSize),
                    ),
                  );
                },
              ),
            ),
          ),

          Positioned.fill(
            left: 40,
            top: -20,
            child: IgnorePointer(
              child: SafeArea(
                minimum: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  children: [
                        Container(height: 10),
                    _buildHeaderCard(theme),
                    const Spacer(),
                    _buildHintCard(),
                  ],
                ),
              ),
            ),
          ),

          // Botão fechar por cima de tudo
          Positioned(
            left: 12,
            top: 12,
            child: SafeArea(
              bottom: false,
              child: ClipOval(
                child: Material(
                  color: const Color.fromARGB(106, 255, 255, 255).withOpacity(0.18),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFDA516).withOpacity(0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.qr_code_scanner, color: Color(0xFFFDA516)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scanner de pedidos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Aponte o QR para localizar rapidamente o pedido.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHintCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.42),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: const Text(
        'Mantenha o celular firme e centralize o QR dentro da moldura para a leitura ser mais rápida.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white70,
          fontSize: 13,
          height: 1.35,
        ),
      ),
    );
  }

  Widget _buildFallbackState(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
    required String? actionLabel,
    required Future<void> Function()? onAction,
  }) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF111827), Color(0xFF050816)],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.24),
                    blurRadius: 28,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDA516).withOpacity(0.16),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: const Color(0xFFFDA516), size: 36),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            _isRetrying ? null : () async => await onAction(),
                        icon: _isRetrying
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.refresh),
                        label: Text(actionLabel),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFDA516),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _retryCamera() async {
    if (_isRetrying) return;

    setState(() {
      _isRetrying = true;
    });

    try {
      await _controller.stop();
      await _controller.start();
    } finally {
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    }
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  const _ScannerOverlayPainter({
    required this.holeOffset,
    required this.holeSize,
  });

  final Offset holeOffset;
  final Size holeSize;

  @override
  void paint(Canvas canvas, Size size) {
    final holeRect = holeOffset & holeSize;
    final holeRadius = Radius.circular(holeSize.width * 0.05);

    final overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.55)
      ..style = PaintingStyle.fill;

    final overlayPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(holeRect, holeRadius));

    canvas.drawPath(overlayPath, overlayPaint);

    final framePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRRect(
      RRect.fromRectAndRadius(holeRect.deflate(1.5), holeRadius),
      framePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) {
    return oldDelegate.holeOffset != holeOffset ||
        oldDelegate.holeSize != holeSize;
  }
}
