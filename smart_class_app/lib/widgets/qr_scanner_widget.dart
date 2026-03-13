import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme.dart';

class QrScannerWidget extends StatefulWidget {
  final Function(String) onScanned;
  final String instruction;

  const QrScannerWidget({
    super.key,
    required this.onScanned,
    this.instruction = 'Point the camera at the QR code',
  });

  @override
  State<QrScannerWidget> createState() => _QrScannerWidgetState();
}

class _QrScannerWidgetState extends State<QrScannerWidget> {
  late final MobileScannerController _controller;
  bool _hasScanned = false;
  bool _showManualEntry = false;

  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController();
  }

  @override
  Widget build(BuildContext context) {
    if (_showManualEntry) {
      return _buildManualEntry();
    }
    return _buildScanner();
  }

  Widget _buildScanner() {
    return Column(
      children: [
        Container(
          height: 280,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.accent, width: 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              MobileScanner(
                controller: _controller,
                errorBuilder: (context, error, child) {
                  // Camera unavailable — switch to manual entry after build frame
                  SchedulerBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _showManualEntry = true);
                  });
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Camera unavailable. Switching to manual entry...',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                            color: Colors.red.shade300, fontSize: 13),
                      ),
                    ),
                  );
                },
                onDetect: (capture) {
                  if (_hasScanned) return;
                  final barcode = capture.barcodes.firstOrNull;
                  if (barcode?.rawValue != null) {
                    setState(() => _hasScanned = true);
                    _controller.stop();
                    widget.onScanned(barcode!.rawValue!);
                  }
                },
              ),
              // Corner overlay
              _buildScanOverlay(),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.qr_code_scanner_rounded,
                color: AppTheme.textSecondary, size: 16),
            const SizedBox(width: 6),
            Text(
              widget.instruction,
              style: GoogleFonts.dmSans(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: () => setState(() => _showManualEntry = true),
          icon: const Icon(Icons.keyboard_alt_outlined,
              size: 16, color: AppTheme.textSecondary),
          label: Text(
            "Can't scan? Enter code manually",
            style: GoogleFonts.dmSans(
                fontSize: 13, color: AppTheme.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildManualEntry() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.accent.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              const Icon(Icons.qr_code_2_rounded,
                  color: AppTheme.accent, size: 48),
              const SizedBox(height: 12),
              Text(
                'QR Code Entry',
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Enter the class code or full QR value below.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _textController,
          decoration: InputDecoration(
            labelText: 'Class Code or QR Value',
            hintText: 'Example: CS301 or SMARTCLASS|CS301|...',
            prefixIcon:
                const Icon(Icons.qr_code_rounded, color: AppTheme.accent),
            labelStyle: GoogleFonts.dmSans(color: AppTheme.textSecondary),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              final value = _textController.text.trim();
              if (value.isNotEmpty) {
                widget.onScanned(value);
              }
            },
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Confirm Code'),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                _hasScanned = false;
                _showManualEntry = false;
              });
            },
            icon: const Icon(Icons.camera_alt_outlined,
                size: 16, color: AppTheme.textSecondary),
            label: Text(
              'Use camera instead',
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: AppTheme.textSecondary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScanOverlay() {
    const color = AppTheme.accent;
    const size = 60.0;
    const thickness = 4.0;

    return Positioned.fill(
      child: Stack(
        children: [
          // Top-left
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: color, width: thickness),
                  left: BorderSide(color: color, width: thickness),
                ),
              ),
            ),
          ),
          // Top-right
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: color, width: thickness),
                  right: BorderSide(color: color, width: thickness),
                ),
              ),
            ),
          ),
          // Bottom-left
          Positioned(
            bottom: 20,
            left: 20,
            child: Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: color, width: thickness),
                  left: BorderSide(color: color, width: thickness),
                ),
              ),
            ),
          ),
          // Bottom-right
          Positioned(
            bottom: 20,
            right: 20,
            child: Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: color, width: thickness),
                  right: BorderSide(color: color, width: thickness),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _textController.dispose();
    super.dispose();
  }
}
