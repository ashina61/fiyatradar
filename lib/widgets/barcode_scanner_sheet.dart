import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../utils/theme.dart';

class BarcodeScannerSheet {
  static Future<String?> scan(BuildContext context, {String? title}) async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) {
        final controller = MobileScannerController();

        Future<void> close([String? value]) async {
          controller.dispose();
          if (Navigator.of(ctx).canPop()) {
            Navigator.of(ctx).pop(value);
          }
        }

        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.6,
            child: Stack(
              children: [
                MobileScanner(
                  controller: controller,
                  onDetect: (capture) {
                    final barcode =
                        capture.barcodes.isNotEmpty ? capture.barcodes.first : null;
                    final value = barcode?.rawValue;
                    if (value != null && value.isNotEmpty) {
                      close(value);
                    }
                  },
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => close(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                      Expanded(
                        child: Text(
                          title ?? 'Barkod Tara',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        onPressed: () => controller.toggleTorch(),
                        icon: const Icon(Icons.flash_on, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 24,
                  left: 24,
                  right: 24,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Text(
                      'Kamerayı barkoda doğru tutun.',
                      style: TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
