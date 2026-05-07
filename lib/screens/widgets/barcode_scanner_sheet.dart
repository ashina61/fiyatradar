import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../ui/components.dart';
import '../../ui/tokens.dart';

/// Modal bottom sheet that runs `mobile_scanner` and pops the first detected
/// barcode value back to the caller. Returns null if the user dismisses.
class BarcodeScannerSheet extends StatefulWidget {
  const BarcodeScannerSheet({super.key, this.title = 'Barkodu okut'});

  final String title;

  static Future<String?> show(BuildContext context, {String? title}) {
    return showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BarcodeScannerSheet(
        title: title ?? 'Barkodu okut',
      ),
    );
  }

  @override
  State<BarcodeScannerSheet> createState() => _BarcodeScannerSheetState();
}

class _BarcodeScannerSheetState extends State<BarcodeScannerSheet> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
    ],
  );
  bool _captured = false;
  bool _torchOn = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDetect(BarcodeCapture capture) {
    if (_captured) return;
    for (final code in capture.barcodes) {
      final raw = (code.rawValue ?? '').trim();
      if (raw.isEmpty) continue;
      _captured = true;
      Navigator.of(context).pop(raw);
      return;
    }
  }

  Future<void> _toggleTorch() async {
    try {
      await _controller.toggleTorch();
      if (!mounted) return;
      setState(() => _torchOn = !_torchOn);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Flaş açılamadı: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewportH = MediaQuery.of(context).size.height;
    final scannerH = (viewportH * 0.55).clamp(320.0, 520.0);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: FR.bgElev,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(28),
          ),
          border: Border.all(color: FR.hairline),
        ),
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          16 + MediaQuery.of(context).viewPadding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: FR.hairline,
                  borderRadius: FRRad.all(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: frDisplay(20, FontWeight.w800),
                  ),
                ),
                FRIconChip(
                  icon: _torchOn
                      ? Icons.flash_on_rounded
                      : Icons.flash_off_rounded,
                  onTap: _toggleTorch,
                ),
                const SizedBox(width: 8),
                FRIconChip(
                  icon: Icons.close_rounded,
                  onTap: () => Navigator.of(context).pop(null),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Kamerayı barkoda doğrult. Otomatik yakalanır.',
              style: frText(12.5, FontWeight.w600, color: FR.ink3),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: FRRad.all(FRRad.l),
              child: SizedBox(
                height: scannerH,
                child: Stack(
                  children: [
                    MobileScanner(
                      controller: _controller,
                      onDetect: _handleDetect,
                      errorBuilder: (context, error, _) {
                        return Container(
                          color: FR.surface,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'Kamera başlatılamadı: ${error.errorDetails?.message ?? error.errorCode.name}',
                            textAlign: TextAlign.center,
                            style: frText(12.5, FontWeight.w600,
                                color: FR.bad),
                          ),
                        );
                      },
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _ScannerOverlayPainter(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!,
                  style: frText(12, FontWeight.w700, color: FR.bad)),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final inset = size.width * 0.10;
    final rect = Rect.fromLTRB(
      inset,
      size.height * 0.25,
      size.width - inset,
      size.height * 0.75,
    );
    final stroke = Paint()
      ..color = FR.gold
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    const corner = 28.0;
    final path = Path();
    // Top-left
    path.moveTo(rect.left, rect.top + corner);
    path.lineTo(rect.left, rect.top);
    path.lineTo(rect.left + corner, rect.top);
    // Top-right
    path.moveTo(rect.right - corner, rect.top);
    path.lineTo(rect.right, rect.top);
    path.lineTo(rect.right, rect.top + corner);
    // Bottom-right
    path.moveTo(rect.right, rect.bottom - corner);
    path.lineTo(rect.right, rect.bottom);
    path.lineTo(rect.right - corner, rect.bottom);
    // Bottom-left
    path.moveTo(rect.left + corner, rect.bottom);
    path.lineTo(rect.left, rect.bottom);
    path.lineTo(rect.left, rect.bottom - corner);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
