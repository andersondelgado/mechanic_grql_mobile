import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../constants/app_colors.dart';

class SignaturePadDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final ValueChanged<Uint8List> onSigned;

  const SignaturePadDialog({
    super.key,
    this.title = 'Firma de Conformidad del Cliente',
    this.subtitle = 'Por favor, dibuje su firma digital en el recuadro para confirmar su aceptación.',
    required this.onSigned,
  });

  static Future<Uint8List?> show(
    BuildContext context, {
    String? title,
    String? subtitle,
  }) {
    return showDialog<Uint8List>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SignaturePadDialog(
        title: title ?? 'Firma de Conformidad del Cliente',
        subtitle: subtitle ??
            'Por favor, dibuje su firma digital en el recuadro para confirmar su aceptación.',
        onSigned: (bytes) {
          Navigator.of(ctx).pop(bytes);
        },
      ),
    );
  }

  @override
  State<SignaturePadDialog> createState() => _SignaturePadDialogState();
}

class _SignaturePadDialogState extends State<SignaturePadDialog> {
  late SignatureController _controller;
  bool _hasDrawn = false;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: 3,
      penColor: const Color(0xFF0F172A),
      exportBackgroundColor: Colors.transparent,
      exportPenColor: const Color(0xFF0F172A),
    );
    _controller.addListener(() {
      final isNotEmpty = _controller.isNotEmpty;
      if (isNotEmpty != _hasDrawn) {
        setState(() {
          _hasDrawn = isNotEmpty;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    if (_controller.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor dibuje su firma antes de confirmar.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    try {
      final bytes = await _controller.toPngBytes();
      if (bytes != null) {
        widget.onSigned(bytes);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al capturar la firma: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.draw_rounded,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.grey),
                  tooltip: 'Cerrar',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Canvas de Firma Táctil
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _hasDrawn ? AppColors.primary : const Color(0xFFE2E8F0),
                  width: 1.5,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Signature(
                    controller: _controller,
                    backgroundColor: const Color(0xFFF8FAFC),
                  ),

                  // Guía de firma (línea punteada)
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 40,
                    child: Container(
                      height: 1,
                      color: Colors.blueGrey.shade300,
                    ),
                  ),

                  // Texto de ayuda
                  Positioned(
                    left: 20,
                    bottom: 18,
                    child: Text(
                      'X  Firme aquí con su dedo o stylus',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blueGrey.shade400,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  if (!_hasDrawn)
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.gesture_rounded,
                            size: 40,
                            color: Colors.blueGrey.shade300,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Área de firma táctil',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blueGrey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Acciones: Limpiar, Cancelar, Confirmar
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 360;
                final isVeryNarrow = constraints.maxWidth < 290;

                final clearButton = OutlinedButton.icon(
                  onPressed: () => _controller.clear(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blueGrey.shade700,
                    side: BorderSide(color: Colors.blueGrey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: isNarrow ? 10 : 14, vertical: 12),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Limpiar', style: TextStyle(fontSize: 13)),
                );

                final cancelButton = TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blueGrey.shade600,
                    padding: EdgeInsets.symmetric(horizontal: isNarrow ? 8 : 14, vertical: 12),
                  ),
                  child: const Text('Cancelar', style: TextStyle(fontSize: 13)),
                );

                final confirmButton = ElevatedButton.icon(
                  onPressed: _handleConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: isNarrow ? 12 : 18, vertical: 12),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: Text(
                    isNarrow ? 'Confirmar' : 'Confirmar Firma',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                );

                if (isVeryNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(child: cancelButton),
                          const SizedBox(width: 8),
                          Expanded(child: confirmButton),
                        ],
                      ),
                      const SizedBox(height: 8),
                      clearButton,
                    ],
                  );
                }

                return Row(
                  children: [
                    clearButton,
                    const Spacer(),
                    cancelButton,
                    const SizedBox(width: 8),
                    confirmButton,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper para convertir bytes a Data URL base64 para la base de datos
String signatureBytesToBase64(Uint8List bytes) {
  return 'data:image/png;base64,${base64Encode(bytes)}';
}
