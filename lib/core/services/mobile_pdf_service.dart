import '../constants/logo_base64.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/peritaje.dart';
import '../../models/recepcion.dart';

class MobilePdfService {
  /// Retorna la imagen del logo oficial de Taller 360 desde Base64
  static pw.MemoryImage? _getLogoImage() {
    try {
      final bytes = base64Decode(kLogoTaller360Base64.replaceAll(RegExp(r'\s+'), ''));
      return pw.MemoryImage(bytes);
    } catch (_) {
      return null;
    }
  }

  /// Decodifica firma base64 si existe en el modelo
  static Uint8List? _decodeSignature(String? sig) {
    if (sig == null || sig.isEmpty) return null;
    try {
      if (sig.startsWith('data:image')) {
        final comma = sig.indexOf(',');
        if (comma != -1) {
          final b64 = sig.substring(comma + 1);
          return base64Decode(b64);
        }
      }
      return base64Decode(sig);
    } catch (_) {
      return null;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 1. INFORME OFICIAL DE PERITAJE IA EN PDF
  // ──────────────────────────────────────────────────────────────────────────
  static Future<Uint8List> generatePeritajePdf(
    Peritaje peritaje, {
    Uint8List? clientSignatureBytes,
  }) async {
    final pdf = pw.Document();

    final sigBytes = clientSignatureBytes ?? _decodeSignature(peritaje.clientSignature);
    final pw.ImageProvider? signatureImage = sigBytes != null ? pw.MemoryImage(sigBytes) : null;

    final analysis = peritaje.analysis;
    final peritajeCode = peritaje.code;
    final date = peritaje.inspectionDate != null && peritaje.inspectionDate!.length >= 10
        ? peritaje.inspectionDate!.substring(0, 10)
        : peritaje.inspectionDate ?? 'Hoy';

    // Severidad color
    final sev = (analysis?.damageSeverity ?? 'moderado').toLowerCase();
    PdfColor sevColor = PdfColors.amber700;
    String sevLabel = 'Moderado';
    if (sev.contains('grave') || sev.contains('alto') || sev.contains('severo')) {
      sevColor = PdfColors.red700;
      sevLabel = 'Grave / Severo';
    } else if (sev.contains('leve') || sev.contains('bajo')) {
      sevColor = PdfColors.green700;
      sevLabel = 'Leve';
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 1. Header Banner Oficial
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 8),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blueGrey900, width: 2)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Container(
                          width: 46,
                          height: 46,
                          padding: const pw.EdgeInsets.all(3),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.white,
                            borderRadius: pw.BorderRadius.circular(8),
                            border: pw.Border.all(color: PdfColors.grey300, width: 1),
                          ),
                          child: _getLogoImage() != null
                              ? pw.Image(_getLogoImage()!, fit: pw.BoxFit.contain)
                              : pw.Center(
                                  child: pw.Text(
                                    '360°',
                                    style: pw.TextStyle(
                                      color: PdfColors.blueGrey900,
                                      fontSize: 16,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                ),
                        ),
                        pw.SizedBox(width: 10),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'TALLER INTEGRAL 360 GARAGE C.A.',
                              style: pw.TextStyle(
                                fontSize: 13,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.blueGrey900,
                              ),
                            ),
                            pw.Text(
                              'Mecánica General • Latonería y Pintura • Peritaje Computarizado',
                              style: const pw.TextStyle(
                                fontSize: 8,
                                color: PdfColors.blueGrey600,
                              ),
                            ),
                            pw.Text(
                              'RIF: J-50123456-7 • Telf: (0212) 555-0360 • Caracas, Venezuela',
                              style: const pw.TextStyle(
                                fontSize: 7,
                                color: PdfColors.blueGrey500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.blueGrey900,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Text(
                            'DICTAMEN N° $peritajeCode',
                            style: pw.TextStyle(
                              color: PdfColors.amber300,
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text('Fecha: $date', style: const pw.TextStyle(fontSize: 8)),
                        pw.Text(
                          'Tipo: ${peritaje.inspectionType.toUpperCase()}',
                          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 6),

              // 2. Título de Documento
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(4),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'FICHA DE CONTROL, INSPECCIÓN Y EVALUACIÓN PERICIAL CON IA GEMINI',
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueGrey900,
                  ),
                ),
              ),
              pw.SizedBox(height: 6),

              // 3. Cajas Lado a Lado: Cliente y Vehículo
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Caja 1: Propietario
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(7),
                      decoration: pw.BoxDecoration(
                        borderRadius: pw.BorderRadius.circular(6),
                        border: pw.Border.all(color: PdfColors.grey300),
                        color: PdfColors.grey50,
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'DATOS DEL PROPIETARIO / CLIENTE',
                            style: pw.TextStyle(
                              fontSize: 7.5,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blueGrey800,
                            ),
                          ),
                          pw.Divider(color: PdfColors.grey300, height: 6, thickness: 0.5),
                          _pdfField('Nombre/Razón', peritaje.clientName ?? 'No especificado'),
                          _pdfField('C.I. / RIF', peritaje.clientTaxId ?? '-'),
                          _pdfField('Teléfono', peritaje.clientPhone ?? '-'),
                          _pdfField('Email', peritaje.clientEmail ?? '-'),
                          _pdfField('Dirección', peritaje.clientAddress ?? '-'),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 8),

                  // Caja 2: Vehículo
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(7),
                      decoration: pw.BoxDecoration(
                        borderRadius: pw.BorderRadius.circular(6),
                        border: pw.Border.all(color: PdfColors.grey300),
                        color: PdfColors.grey50,
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                'DATOS DEL VEHÍCULO',
                                style: pw.TextStyle(
                                  fontSize: 7.5,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.blueGrey800,
                                ),
                              ),
                              pw.Container(
                                padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: pw.BoxDecoration(
                                  color: PdfColors.amber400,
                                  borderRadius: pw.BorderRadius.circular(3),
                                ),
                                child: pw.Text(
                                  peritaje.licensePlate ?? 'SIN PLACA',
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          pw.Divider(color: PdfColors.grey300, height: 6, thickness: 0.5),
                          _pdfField('Marca / Modelo', '${peritaje.vehicleBrand ?? ''} ${peritaje.vehicleModel ?? ''}'.trim()),
                          _pdfField('Año / Color', '${peritaje.vehicleYear ?? '-'} • ${peritaje.vehicleColor ?? '-'}'),
                          _pdfField('Kilometraje', '${peritaje.vehicleMileage ?? '-'} km'),
                          _pdfField('VIN / Chasis', peritaje.vehicleVin ?? 'No registrado'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),

              // 4. Panel Evaluación Pericial IA Gemini
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.purple200, width: 1.5),
                  color: PdfColors.purple50,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Header IA
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'EVALUACIÓN PERICIAL CON IA GEMINI MULTIMODAL',
                          style: pw.TextStyle(
                            fontSize: 8.5,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.purple900,
                          ),
                        ),
                        pw.Row(
                          children: [
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: pw.BoxDecoration(
                                color: sevColor,
                                borderRadius: pw.BorderRadius.circular(8),
                              ),
                              child: pw.Text(
                                sevLabel.toUpperCase(),
                                style: pw.TextStyle(
                                  fontSize: 7.5,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.white,
                                ),
                              ),
                            ),
                            if (analysis?.confidenceScore != null) ...[
                              pw.SizedBox(width: 4),
                              pw.Container(
                                padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: pw.BoxDecoration(
                                  color: PdfColors.purple200,
                                  borderRadius: pw.BorderRadius.circular(8),
                                ),
                                child: pw.Text(
                                  '${analysis!.confidenceScore}% Certeza',
                                  style: pw.TextStyle(
                                    fontSize: 7.5,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.purple900,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 6),

                    // Métricas (3 columnas)
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: _pdfMetricBox(
                            'TIPO DE DAÑO',
                            analysis?.damageType?.replaceAll('_', ' ') ?? 'Revisión General',
                          ),
                        ),
                        pw.SizedBox(width: 6),
                        pw.Expanded(
                          child: _pdfMetricBox(
                            'MANO DE OBRA ESTIMADA',
                            '${analysis?.repairEstimatedHours ?? 0} Horas de taller',
                          ),
                        ),
                        pw.SizedBox(width: 6),
                        pw.Expanded(
                          child: _pdfMetricBox(
                            'ESTADO DICTAMEN',
                            analysis?.status?.toUpperCase() ?? 'COMPLETADO',
                            textColor: PdfColors.green800,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 6),

                    // Partes Afectadas
                    if (analysis != null && analysis.affectedParts.isNotEmpty) ...[
                      pw.Text(
                        'Partes y Componentes Afectados:',
                        style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Wrap(
                        spacing: 4,
                        runSpacing: 3,
                        children: analysis.affectedParts.map((p) {
                          return pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.red50,
                              borderRadius: pw.BorderRadius.circular(3),
                              border: pw.Border.all(color: PdfColors.red200),
                            ),
                            child: pw.Text('• $p', style: const pw.TextStyle(fontSize: 7, color: PdfColors.red800)),
                          );
                        }).toList(),
                      ),
                      pw.SizedBox(height: 4),
                    ],

                    // Repuestos Necesarios
                    if (analysis != null && analysis.partsNeeded.isNotEmpty) ...[
                      pw.Text(
                        'Repuestos Sugeridos para Sustitución:',
                        style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: analysis.partsNeeded.map((r) {
                          return pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.white,
                              borderRadius: pw.BorderRadius.circular(3),
                              border: pw.Border.all(color: PdfColors.grey300),
                            ),
                            child: pw.Text('✓ $r', style: const pw.TextStyle(fontSize: 7, color: PdfColors.blueGrey800)),
                          );
                        }).toList(),
                      ),
                      pw.SizedBox(height: 4),
                    ],

                    // Diagnóstico y Conclusiones del Perito IA
                    if (analysis?.observations != null && analysis!.observations!.isNotEmpty) ...[
                      pw.Container(
                        padding: const pw.EdgeInsets.all(5),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          borderRadius: pw.BorderRadius.circular(4),
                          border: pw.Border.all(color: PdfColors.purple200),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Diagnóstico Técnico y Conclusiones del Perito IA:',
                              style: pw.TextStyle(
                                fontSize: 7,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.purple900,
                              ),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              analysis.observations!,
                              style: const pw.TextStyle(fontSize: 7, color: PdfColors.blueGrey900),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(height: 5),

              // 5. Observaciones Generales
              if (peritaje.observations != null && peritaje.observations!.isNotEmpty) ...[
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(5),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(4),
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'OBSERVACIONES GENERALES:',
                        style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
                      ),
                      pw.Text(
                        peritaje.observations!,
                        style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.blueGrey900),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 6),
              ],

              pw.Spacer(),

              // 6. Firmas (Inspector y Cliente con Firma Digital)
              pw.Container(
                padding: const pw.EdgeInsets.only(top: 8),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(top: pw.BorderSide(color: PdfColors.blueGrey900, width: 1.5)),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    // Firma Inspector
                    pw.Expanded(
                      child: pw.Column(
                        children: [
                          pw.Container(
                            height: 38,
                            alignment: pw.Alignment.bottomCenter,
                            child: pw.Text(
                              peritaje.inspectorName ?? 'Inspector Técnico',
                              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                          pw.Container(height: 1, color: PdfColors.grey400, margin: const pw.EdgeInsets.symmetric(vertical: 2)),
                          pw.Text(
                            'FIRMA DEL INSPECTOR / PERITO',
                            style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 40),

                    // Firma Cliente
                    pw.Expanded(
                      child: pw.Column(
                        children: [
                          pw.Container(
                            height: 38,
                            alignment: pw.Alignment.center,
                            child: signatureImage != null
                                ? pw.Image(signatureImage, fit: pw.BoxFit.contain)
                                : pw.Text(
                                    peritaje.clientName ?? 'Cliente',
                                    style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                                  ),
                          ),
                          pw.Container(height: 1, color: PdfColors.grey400, margin: const pw.EdgeInsets.symmetric(vertical: 2)),
                          pw.Text(
                            signatureImage != null
                                ? 'FIRMA DIGITAL DE CONFORMIDAD DEL CLIENTE'
                                : 'FIRMA DE CONFORMIDAD DEL CLIENTE',
                            style: pw.TextStyle(
                              fontSize: 7,
                              fontWeight: pw.FontWeight.bold,
                              color: signatureImage != null ? PdfColors.green900 : PdfColors.grey600,
                            ),
                          ),
                          if (signatureImage != null)
                            pw.Text(
                              'Validado digitalmente • ${peritaje.clientSignatureDate ?? date}',
                              style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey600),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 4),

              // Pie de página
              pw.Center(
                child: pw.Text(
                  'Documento de diagnóstico y evaluación asistido por IA generativa • Taller Integral 360 Garage C.A.',
                  style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey500),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 2. FICHA TÉCNICA OFICIAL DE RECEPCIÓN EN PDF
  // ──────────────────────────────────────────────────────────────────────────
  static Future<Uint8List> generateRecepcionPdf(
    Recepcion recepcion, {
    Uint8List? clientSignatureBytes,
  }) async {
    final pdf = pw.Document();

    final sigBytes = clientSignatureBytes ?? _decodeSignature(recepcion.clientSignature);
    final pw.ImageProvider? signatureImage = sigBytes != null ? pw.MemoryImage(sigBytes) : null;

    final receiptCode = recepcion.code;
    final date = recepcion.entryDate != null && recepcion.entryDate!.length >= 10
        ? recepcion.entryDate!.substring(0, 10)
        : recepcion.entryDate ?? 'Hoy';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 8),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blueGrey900, width: 2)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Row(
                      children: [
                        pw.Container(
                          width: 46,
                          height: 46,
                          padding: const pw.EdgeInsets.all(3),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.white,
                            borderRadius: pw.BorderRadius.circular(8),
                            border: pw.Border.all(color: PdfColors.grey300, width: 1),
                          ),
                          child: _getLogoImage() != null
                              ? pw.Image(_getLogoImage()!, fit: pw.BoxFit.contain)
                              : pw.Center(
                                  child: pw.Text(
                                    '360°',
                                    style: pw.TextStyle(color: PdfColors.blueGrey900, fontSize: 16, fontWeight: pw.FontWeight.bold),
                                  ),
                                ),
                        ),
                        pw.SizedBox(width: 10),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'TALLER INTEGRAL 360 GARAGE C.A.',
                              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
                            ),
                            pw.Text('Mecánica General • Latonería y Pintura • Peritaje Computarizado',
                                style: const pw.TextStyle(fontSize: 8, color: PdfColors.blueGrey600)),
                            pw.Text('RIF: J-50123456-7 • Telf: (0212) 555-0360 • Caracas, Venezuela',
                                style: const pw.TextStyle(fontSize: 7, color: PdfColors.blueGrey500)),
                          ],
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.blue900,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Text(
                            'RECEPCIÓN N° $receiptCode',
                            style: pw.TextStyle(color: PdfColors.white, fontSize: 9, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text('Fecha Entrada: $date', style: const pw.TextStyle(fontSize: 8)),
                        if (recepcion.exitDate != null)
                          pw.Text('Est. Salida: ${recepcion.exitDate}', style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 6),

              // Title
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(4),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'FICHA TÉCNICA OFICIAL DE RECEPCIÓN Y ESTADO DE INGRESO DEL VEHÍCULO',
                  style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
                ),
              ),
              pw.SizedBox(height: 6),

              // Boxes
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(7),
                      decoration: pw.BoxDecoration(
                        borderRadius: pw.BorderRadius.circular(6),
                        border: pw.Border.all(color: PdfColors.grey300),
                        color: PdfColors.grey50,
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('DATOS DEL PROPIETARIO',
                              style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
                          pw.Divider(color: PdfColors.grey300, height: 6, thickness: 0.5),
                          _pdfField('Nombre', recepcion.ownerName ?? '-'),
                          _pdfField('C.I. / RIF', recepcion.ownerTaxId ?? '-'),
                          _pdfField('Teléfono', recepcion.phone ?? '-'),
                          _pdfField('Dirección', recepcion.address ?? '-'),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(7),
                      decoration: pw.BoxDecoration(
                        borderRadius: pw.BorderRadius.circular(6),
                        border: pw.Border.all(color: PdfColors.grey300),
                        color: PdfColors.grey50,
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('DATOS DEL VEHÍCULO',
                                  style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
                              pw.Container(
                                padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: pw.BoxDecoration(color: PdfColors.amber400, borderRadius: pw.BorderRadius.circular(3)),
                                child: pw.Text(recepcion.licensePlate ?? 'SIN PLACA',
                                    style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                              ),
                            ],
                          ),
                          pw.Divider(color: PdfColors.grey300, height: 6, thickness: 0.5),
                          _pdfField('Marca / Modelo', '${recepcion.brand ?? ''} ${recepcion.model ?? ''}'.trim()),
                          _pdfField('Año / Color', '${recepcion.year ?? '-'} • ${recepcion.color ?? '-'}'),
                          _pdfField('Kilometraje', '${recepcion.mileage ?? '-'} km'),
                          _pdfField('Nivel Combustible', recepcion.fuelLevel ?? '1/2'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),

              // Custodia y Personal Responsable
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 7),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey50,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Recibido por: ${recepcion.receivedBy != null && recepcion.receivedBy!.isNotEmpty ? recepcion.receivedBy! : '-'}',
                      style: const pw.TextStyle(fontSize: 7, color: PdfColors.blueGrey800),
                    ),
                    pw.Text(
                      'Entregado por: ${recepcion.deliveredBy != null && recepcion.deliveredBy!.isNotEmpty ? recepcion.deliveredBy! : (recepcion.ownerName ?? 'Cliente')}',
                      style: const pw.TextStyle(fontSize: 7, color: PdfColors.blueGrey800),
                    ),
                    pw.Text(
                      'Técnico Asignado: ${recepcion.assignedTechnician != null && recepcion.assignedTechnician!.isNotEmpty ? recepcion.assignedTechnician! : 'YEISON TORRES'}',
                      style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 6),

              // Motivo y Diagnóstico Inicial
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(7),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.blue200),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('MOTIVO DE INGRESO Y REQUERIMIENTO DEL CLIENTE:',
                        style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                    pw.SizedBox(height: 2),
                    pw.Text(recepcion.reasonForEntry ?? 'Revisión técnica general y diagnóstico.',
                        style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.blueGrey900)),
                    if (recepcion.workPerformed != null && recepcion.workPerformed!.isNotEmpty) ...[
                      pw.SizedBox(height: 4),
                      pw.Text('OBSERVACIONES DE RECEPCIÓN:',
                          style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                      pw.Text(recepcion.workPerformed!, style: const pw.TextStyle(fontSize: 7, color: PdfColors.blueGrey900)),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(height: 6),

              // Checklist Resumen
              pw.Container(
                padding: const pw.EdgeInsets.all(7),
                decoration: pw.BoxDecoration(
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.grey300),
                  color: PdfColors.grey50,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('INVENTARIO Y CHECKLIST DEL ESTADO DE RECEPCIÓN:',
                        style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
                    pw.Divider(color: PdfColors.grey300, height: 6, thickness: 0.5),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            '• Luces / Faros: Conforme\n• Cauchos / Neumáticos: Bueno\n• Espejos y Parabrisas: Operativo\n• Herramientas / Gato: Presente',
                            style: const pw.TextStyle(fontSize: 7, color: PdfColors.blueGrey700),
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            '• Documentos: En regla\n• Llave de Encendido: Recibida\n• Radio / Panel: Operativo\n• Nivel de Batería: Con carga',
                            style: const pw.TextStyle(fontSize: 7, color: PdfColors.blueGrey700),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // Cláusula de Custodia
              pw.Container(
                padding: const pw.EdgeInsets.all(4),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey50,
                  borderRadius: pw.BorderRadius.circular(4),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Text(
                  'CLÁUSULA DE CUSTODIA Y CONFORMIDAD: El cliente autoriza los trabajos mencionados y los desplazamientos necesarios para pruebas mecánicas bajo su cuenta y riesgo. El taller no se hace responsable por pérdidas de objetos de valor no especificados en este reporte.',
                  style: const pw.TextStyle(fontSize: 5.5, color: PdfColors.blueGrey600),
                  textAlign: pw.TextAlign.justify,
                ),
              ),
              pw.SizedBox(height: 4),

              // Firmas
              pw.Container(
                padding: const pw.EdgeInsets.only(top: 8),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(top: pw.BorderSide(color: PdfColors.blueGrey900, width: 1.5)),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        children: [
                          pw.Container(
                            height: 38,
                            alignment: pw.Alignment.bottomCenter,
                            child: pw.Text('Receptor / Jefe de Taller',
                                style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Container(height: 1, color: PdfColors.grey400, margin: const pw.EdgeInsets.symmetric(vertical: 2)),
                          pw.Text('FIRMA DEL RECEPTOR DEL TALLER',
                              style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 40),
                    pw.Expanded(
                      child: pw.Column(
                        children: [
                          pw.Container(
                            height: 38,
                            alignment: pw.Alignment.center,
                            child: signatureImage != null
                                ? pw.Image(signatureImage, fit: pw.BoxFit.contain)
                                : pw.Text(recepcion.ownerName ?? 'Cliente',
                                    style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Container(height: 1, color: PdfColors.grey400, margin: const pw.EdgeInsets.symmetric(vertical: 2)),
                          pw.Text(
                            signatureImage != null
                                ? 'FIRMA DIGITAL DE CONFORMIDAD DEL CLIENTE'
                                : 'FIRMA DE CONFORMIDAD DEL CLIENTE',
                            style: pw.TextStyle(
                              fontSize: 7,
                              fontWeight: pw.FontWeight.bold,
                              color: signatureImage != null ? PdfColors.green900 : PdfColors.grey600,
                            ),
                          ),
                          if (signatureImage != null)
                            pw.Text('Validado digitalmente • ${recepcion.clientSignatureDate ?? date}',
                                style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 4),

              pw.Center(
                child: pw.Text(
                  'Ficha Técnica y Acta de Recepción Vehicular • Taller Integral 360 Garage C.A.',
                  style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey500),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Utilidades de Layout de PDF
  // ──────────────────────────────────────────────────────────────────────────
  static pw.Widget _pdfField(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 58,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey700),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 7, color: PdfColors.black),
              maxLines: 1,
              overflow: pw.TextOverflow.clip,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _pdfMetricBox(String label, String value, {PdfColor textColor = PdfColors.blueGrey900}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: PdfColors.purple100),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey500)),
          pw.SizedBox(height: 1),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: textColor),
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  /// Visualizar e imprimir/compartir el PDF
  static Future<void> previewPdf(
    BuildContext context,
    Uint8List pdfBytes,
    String title,
  ) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: title,
    );
  }

  /// Compartir directamente el PDF
  static Future<void> sharePdf(Uint8List pdfBytes, String fileName) async {
    await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
  }
}
