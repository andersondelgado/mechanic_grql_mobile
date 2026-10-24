import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/providers.dart';
import '../../../../core/services/mobile_pdf_service.dart';
import '../../../../core/widgets/signature_pad_dialog.dart';
import '../../../../models/vehiculo.dart';
import '../../../../models/cliente.dart';
import '../../../../models/peritaje.dart';
import '../../../../models/recepcion.dart';
import '../../../../models/cotizacion.dart';

class PortalClientePage extends ConsumerStatefulWidget {
  final Vehiculo vehicle;
  final Cliente? client;

  const PortalClientePage({
    super.key,
    required this.vehicle,
    this.client,
  });

  @override
  ConsumerState<PortalClientePage> createState() => _PortalClientePageState();
}

class _PortalClientePageState extends ConsumerState<PortalClientePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _error;

  Recepcion? _recepcion;
  Peritaje? _peritaje;
  Cotizacion? _cotizacion;

  Uint8List? _recepcionSignatureBytes;
  Uint8List? _peritajeSignatureBytes;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadVehicleRecords();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Uint8List? _parseSignature(String? sig) {
    if (sig == null || sig.isEmpty) return null;
    try {
      if (sig.startsWith('data:image')) {
        final comma = sig.indexOf(',');
        if (comma != -1) {
          return base64Decode(sig.substring(comma + 1));
        }
      }
      return base64Decode(sig);
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadVehicleRecords() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final clientApi = ref.read(apiClientProvider);
      final vId = widget.vehicle.id;

      if (vId == null || vId.isEmpty) {
        throw Exception("ID de vehículo no válido");
      }

      // Consultas en paralelo para rapidez
      final results = await Future.wait([
        clientApi.getRecepcionesForVehicle(vId),
        clientApi.getPeritajesForVehicle(vId),
        clientApi.getQuotesForVehicle(vId),
      ]);

      final recepcionesList = results[0];
      final peritajesList = results[1];
      final quotesList = results[2];

      if (recepcionesList.isNotEmpty) {
        _recepcion = Recepcion.fromJson(recepcionesList.first);
        _recepcionSignatureBytes = _parseSignature(_recepcion?.clientSignature);
      }

      if (peritajesList.isNotEmpty) {
        _peritaje = Peritaje.fromJson(peritajesList.first);
        _peritajeSignatureBytes = _parseSignature(_peritaje?.clientSignature);
      }

      if (quotesList.isNotEmpty) {
        _cotizacion = Cotizacion.fromJson(quotesList.first);
      }
    } catch (e) {
      _error = 'Inconveniente al cargar el historial del vehículo: $e';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Firmar Peritaje ──────────────────────────────────────────────────────
  Future<void> _signPeritaje() async {
    if (_peritaje == null) return;

    final bytes = await SignaturePadDialog.show(
      context,
      title: 'Firma de Conformidad del Peritaje IA',
      subtitle: 'Al firmar, valida el informe de inspección técnica del vehículo ${widget.vehicle.licensePlate}.',
    );

    if (bytes != null && mounted) {
      setState(() {
        _peritajeSignatureBytes = bytes;
        _peritaje = _peritaje!.copyWith(
          clientSignature: signatureBytesToBase64(bytes),
          clientSignatureDate: DateTime.now().toString().substring(0, 16),
        );
      });

      if (_peritaje!.id != null) {
        try {
          final clientApi = ref.read(apiClientProvider);
          await clientApi.savePeritajeSignature(
            _peritaje!.id!,
            signatureBytesToBase64(bytes),
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Firma del Peritaje registrada con éxito.'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } catch (_) {}
      }
    }
  }

  // ─── Firmar Ficha Técnica / Recepción ────────────────────────────────────
  Future<void> _signRecepcion() async {
    if (_recepcion == null) return;

    final bytes = await SignaturePadDialog.show(
      context,
      title: 'Firma de Recepción del Vehículo',
      subtitle: 'Al firmar, valida la ficha técnica y estado de entrega de su vehículo.',
    );

    if (bytes != null && mounted) {
      setState(() {
        _recepcionSignatureBytes = bytes;
        _recepcion = _recepcion!.copyWith(
          clientSignature: signatureBytesToBase64(bytes),
          clientSignatureDate: DateTime.now().toString().substring(0, 16),
        );
      });

      if (_recepcion!.id != null) {
        try {
          final clientApi = ref.read(apiClientProvider);
          await clientApi.saveRecepcionSignature(
            _recepcion!.id!,
            signatureBytesToBase64(bytes),
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Firma de recepción registrada con éxito.'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } catch (_) {}
      }
    }
  }

  // ─── Generar y Ver PDF Peritaje ──────────────────────────────────────────
  Future<void> _downloadPeritajePdf() async {
    if (_peritaje == null) return;
    try {
      final pdfBytes = await MobilePdfService.generatePeritajePdf(
        _peritaje!,
        clientSignatureBytes: _peritajeSignatureBytes,
      );
      if (mounted) {
        await MobilePdfService.previewPdf(
          context,
          pdfBytes,
          'Informe_Peritaje_${widget.vehicle.licensePlate}.pdf',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar PDF de Peritaje: $e')),
        );
      }
    }
  }

  // ─── Generar y Ver PDF Recepción ─────────────────────────────────────────
  Future<void> _downloadRecepcionPdf() async {
    if (_recepcion == null) return;
    try {
      final pdfBytes = await MobilePdfService.generateRecepcionPdf(
        _recepcion!,
        clientSignatureBytes: _recepcionSignatureBytes,
      );
      if (mounted) {
        await MobilePdfService.previewPdf(
          context,
          pdfBytes,
          'Ficha_Recepcion_${widget.vehicle.licensePlate}.pdf',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar PDF de Recepción: $e')),
        );
      }
    }
  }

  // ─── Calcular Estado Actual para Timeline ────────────────────────────────
  int _getCurrentStepIndex() {
    if (_recepcion?.status == 'completed' || _recepcion?.status == 'completado') {
      return 5; // Listo para entrega
    }
    if (_cotizacion != null && _cotizacion!.status == 'aprobado') {
      return 3; // En reparación
    }
    if (_cotizacion != null) {
      return 2; // Presupuesto emitido
    }
    if (_peritaje != null) {
      return 1; // Peritaje IA
    }
    return 0; // Recepción inicial
  }

  @override
  Widget build(BuildContext context) {
    final clientName = widget.client?.nombre ?? widget.vehicle.clientName ?? 'Cliente Estimado';
    final currentStep = _getCurrentStepIndex();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Portal del Conductor',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
            Text(
              'Vehículo: ${widget.vehicle.licensePlate} • $clientName',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.secondary),
          onPressed: () => context.go('/consulta-cliente'),
          tooltip: 'Cambiar de vehículo',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _loadVehicleRecords,
            tooltip: 'Actualizar estado',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          isScrollable: true,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.timeline_rounded, size: 18), text: 'Estado & Timeline'),
            Tab(icon: Icon(Icons.psychology_rounded, size: 18), text: 'Informe Peritaje IA'),
            Tab(icon: Icon(Icons.receipt_long_rounded, size: 18), text: 'Ficha Técnica Recepción'),
            Tab(icon: Icon(Icons.request_quote_rounded, size: 18), text: 'Presupuesto'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null && _recepcion == null && _peritaje == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.danger),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadVehicleRecords,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                // Tab 1: Estado del Vehículo & Timeline
                _buildTimelineTab(currentStep),

                // Tab 2: Informe de Peritaje con IA Gemini
                _buildPeritajeTab(),

                // Tab 3: Ficha Técnica de Recepción
                _buildRecepcionTab(),

                // Tab 4: Presupuesto & Costos
                _buildPresupuestoTab(),
              ],
            ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TAB 1: TIMELINE DE ESTADO DEL VEHÍCULO
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildTimelineTab(int currentStep) {
    final steps = [
      {'title': '1. Recepción en Taller', 'desc': 'Vehículo ingresado e inventariado'},
      {'title': '2. Peritaje Técnico IA', 'desc': 'Escaneo multimodal de carrocería y daños'},
      {'title': '3. Presupuesto & Cotización', 'desc': 'Estimación de repuestos y mano de obra'},
      {'title': '4. Reparación en Taller', 'desc': 'Mecánica, latonería y sustitución de piezas'},
      {'title': '5. Control de Calidad', 'desc': 'Pruebas de ruta, pintura y verificación'},
      {'title': '6. Listo para Entrega', 'desc': 'Vehículo listo para su retiro en taller'},
    ];

    return RefreshIndicator(
      onRefresh: _loadVehicleRecords,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Vehicle Hero Card
            _buildVehicleHeroCard(),
            const SizedBox(height: 16),

            // Card del Progreso
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.speed_rounded, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Estado Operativo Actual',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Stepper Vertical
                    for (int i = 0; i < steps.length; i++) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: i <= currentStep
                                      ? (i == currentStep ? AppColors.primary : AppColors.success)
                                      : const Color(0xFFF1F5F9),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: i <= currentStep
                                        ? Colors.transparent
                                        : const Color(0xFFCBD5E1),
                                    width: 1.5,
                                  ),
                                ),
                                child: Icon(
                                  i < currentStep
                                      ? Icons.check_rounded
                                      : (i == currentStep ? Icons.play_arrow_rounded : Icons.circle),
                                  size: i < currentStep ? 18 : (i == currentStep ? 18 : 8),
                                  color: i <= currentStep ? Colors.white : const Color(0xFF94A3B8),
                                ),
                              ),
                              if (i < steps.length - 1)
                                Container(
                                  width: 2,
                                  height: 38,
                                  color: i < currentStep ? AppColors.success : const Color(0xFFE2E8F0),
                                ),
                            ],
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4, bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    steps[i]['title']!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: i == currentStep ? FontWeight.w900 : FontWeight.bold,
                                      color: i <= currentStep ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    steps[i]['desc']!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: i <= currentStep ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TAB 2: INFORME DE PERITAJE CON IA GEMINI
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildPeritajeTab() {
    if (_peritaje == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.psychology_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                'Sin peritaje técnico registrado aún',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
              ),
              SizedBox(height: 6),
              Text(
                'El equipo técnico del taller generará la evaluación con IA Gemini próximamente.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
      );
    }

    final analysis = _peritaje!.analysis;
    final sev = (analysis?.damageSeverity ?? 'moderado').toLowerCase();
    Color sevColor = AppColors.warning;
    String sevLabel = 'Moderado';
    if (sev.contains('grave') || sev.contains('alto') || sev.contains('severo')) {
      sevColor = AppColors.danger;
      sevLabel = 'Grave / Severo';
    } else if (sev.contains('leve')) {
      sevColor = AppColors.success;
      sevLabel = 'Leve';
    }

    final hasSignature = _peritajeSignatureBytes != null ||
        (_peritaje!.clientSignature != null && _peritaje!.clientSignature!.isNotEmpty);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner de Peritaje
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFFE9D5FF), width: 1.5),
            ),
            color: const Color(0xFFFAF5FF),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7E22CE),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _peritaje!.code,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF581C87),
                                ),
                              ),
                              const Text(
                                'Evaluación Pericial con IA Gemini',
                                style: TextStyle(fontSize: 11, color: Color(0xFF7E22CE)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: sevColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          sevLabel.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Resumen de daño
                  if (analysis?.damageType != null) ...[
                    _specRow('Tipo de Daño:', analysis!.damageType!.replaceAll('_', ' ')),
                    _specRow('Mano de Obra:', '${analysis.repairEstimatedHours ?? 0} Horas estimadas'),
                    if (analysis.confidenceScore != null)
                      _specRow('Nivel de Certeza IA:', '${analysis.confidenceScore}% Confiabilidad'),
                    const SizedBox(height: 10),
                  ],

                  // Piezas Afectadas
                  if (analysis != null && analysis.affectedParts.isNotEmpty) ...[
                    const Text(
                      'Partes de Carrocería Afectadas:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: analysis.affectedParts.map((p) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: Text(
                            '• $p',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF991B1B), fontWeight: FontWeight.w600),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Diagnóstico IA
                  if (analysis?.observations != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE9D5FF)),
                      ),
                      child: Text(
                        analysis!.observations!,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.4),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Estado de Firma de Conformidad
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: hasSignature ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0)),
            ),
            color: hasSignature ? const Color(0xFFF0FDF4) : Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        hasSignature ? Icons.verified_rounded : Icons.pending_actions_rounded,
                        color: hasSignature ? AppColors.success : AppColors.warning,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasSignature ? 'Conformidad Firmada por el Cliente' : 'Firma de Conformidad Pendiente',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: hasSignature ? const Color(0xFF166534) : const Color(0xFF854D0E),
                              ),
                            ),
                            Text(
                              hasSignature
                                  ? 'Usted ha firmado digitalmente este dictamen pericial.'
                                  : 'Firme en pantalla con su dedo para validar este reporte.',
                              style: TextStyle(
                                fontSize: 11,
                                color: hasSignature ? const Color(0xFF15803D) : const Color(0xFF713F12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_peritajeSignatureBytes != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Image.memory(_peritajeSignatureBytes!, fit: BoxFit.contain),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Botones de Acción
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _signPeritaje,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: hasSignature ? AppColors.success : AppColors.primary,
                    side: BorderSide(color: hasSignature ? AppColors.success : AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: Icon(hasSignature ? Icons.check_circle_rounded : Icons.draw_rounded, size: 18),
                  label: Text(
                    hasSignature ? 'Volver a Firmar' : 'Firmar Dictamen',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _downloadPeritajePdf,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                  label: const Text(
                    'Descargar PDF',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Botón ver informe detallado en pantalla completa
          TextButton.icon(
            onPressed: () {
              context.push('/peritajes/informe', extra: _peritaje);
            },
            icon: const Icon(Icons.fullscreen_rounded, size: 18),
            label: const Text('Ver Ficha Oficial de Peritaje Completa'),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TAB 3: FICHA TÉCNICA DE RECEPCIÓN
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildRecepcionTab() {
    if (_recepcion == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                'Sin ficha de recepción activa',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
              ),
              SizedBox(height: 6),
              Text(
                'No se ha registrado una orden de entrada para este vehículo.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
      );
    }

    final rec = _recepcion!;
    final hasSignature = _recepcionSignatureBytes != null ||
        (rec.clientSignature != null && rec.clientSignature!.isNotEmpty);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tarjeta de Recepción
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFFBFDBFE), width: 1.5),
            ),
            color: const Color(0xFFF0F9FF),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.assignment_turned_in_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rec.code,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0369A1),
                                ),
                              ),
                              const Text(
                                'Ficha Oficial de Recepción',
                                style: TextStyle(fontSize: 11, color: Color(0xFF0284C7)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: rec.status == 'completed' || rec.status == 'completado'
                              ? AppColors.success
                              : AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          rec.status.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _specRow('Fecha de Entrada:', rec.entryDate ?? '-'),
                  if (rec.exitDate != null)
                    _specRow('Fecha Est. Entrega:', rec.exitDate!),
                  _specRow('Nivel Combustible:', rec.fuelLevel ?? '1/2'),
                  _specRow('Kilometraje:', '${rec.mileage ?? '-'} km'),
                  const SizedBox(height: 10),

                  if (rec.reasonForEntry != null && rec.reasonForEntry!.isNotEmpty) ...[
                    const Text(
                      'Motivo de Entrada:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBAE6FD)),
                      ),
                      child: Text(
                        rec.reasonForEntry!,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Estado de Firma
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: hasSignature ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0)),
            ),
            color: hasSignature ? const Color(0xFFF0FDF4) : Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        hasSignature ? Icons.verified_rounded : Icons.edit_note_rounded,
                        color: hasSignature ? AppColors.success : AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasSignature ? 'Ficha de Recepción Firmada' : 'Firma de Recepción Pendiente',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: hasSignature ? const Color(0xFF166534) : const Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              hasSignature
                                  ? 'Su firma certifica el estado en que entregó el vehículo al taller.'
                                  : 'Firme para validar el inventario inicial del vehículo.',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_recepcionSignatureBytes != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Image.memory(_recepcionSignatureBytes!, fit: BoxFit.contain),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Botones de Acción
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _signRecepcion,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: hasSignature ? AppColors.success : AppColors.primary,
                    side: BorderSide(color: hasSignature ? AppColors.success : AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: Icon(hasSignature ? Icons.check_circle_rounded : Icons.draw_rounded, size: 18),
                  label: Text(
                    hasSignature ? 'Volver a Firmar' : 'Firmar Recepción',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _downloadRecepcionPdf,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                  label: const Text(
                    'Descargar PDF',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TAB 4: PRESUPUESTO & COTIZACIÓN
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildPresupuestoTab() {
    if (_cotizacion == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.request_quote_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                'Sin presupuesto emitido por el momento',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
              ),
              SizedBox(height: 6),
              Text(
                'Una vez completado el peritaje técnico, se generará la cotización de repuestos y mano de obra.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
      );
    }

    final q = _cotizacion!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        q.quoteNumber ?? 'Presupuesto Oficial',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: q.status.toLowerCase() == 'aprobado'
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          q.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: q.status.toLowerCase() == 'aprobado'
                                ? const Color(0xFF15803D)
                                : const Color(0xFFB45309),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _specRow('Fecha de Emisión:', q.quoteDate ?? '-'),
                  if (q.validUntil != null)
                    _specRow('Válido Hasta:', q.validUntil!),
                  const Divider(height: 20, color: Color(0xFFE2E8F0)),

                  // Desglose
                  _priceRow('Subtotal:', '\$${q.subtotal.toStringAsFixed(2)}'),
                  if (q.taxAmount > 0)
                    _priceRow('I.V.A.:', '\$${q.taxAmount.toStringAsFixed(2)}'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL ESTIMADO:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '\$${q.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (q.notes != null && q.notes!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Text(
                      'Notas del Presupuesto:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 4),
                    Text(q.notes!, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Widgets Auxiliares
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildVehicleHeroCard() {
    final v = widget.vehicle;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.directions_car_rounded, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          v.licensePlate,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        v.brand ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${v.model ?? ''} • ${v.color ?? ''}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  if (v.vin != null && v.vin!.isNotEmpty)
                    Text(
                      'VIN: ${v.vin}',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _specRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }
}
