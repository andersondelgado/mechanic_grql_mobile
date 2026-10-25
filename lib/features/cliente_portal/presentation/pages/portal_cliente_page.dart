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

class _PortalClientePageState extends ConsumerState<PortalClientePage> {
  late final PageController _pageController;
  int _selectedIndex = 0;
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
    _pageController = PageController(initialPage: 0);
    _loadVehicleRecords();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    }
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
      final vId = widget.vehicle.id?.trim() ?? '';
      final plate = widget.vehicle.licensePlate.trim();

      if (vId.isEmpty && plate.isEmpty) {
        throw Exception("ID o Placa de vehículo no válida");
      }

      // Consultas en paralelo para rapidez (soporta tanto UUID como Placa)
      final results = await Future.wait([
        clientApi.getRecepcionesForVehicle(vId, licensePlate: plate),
        clientApi.getPeritajesForVehicle(vId, licensePlate: plate),
        clientApi.getQuotesForVehicle(vId, licensePlate: plate),
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
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => context.go('/consulta-cliente'),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Portal del Conductor',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Text(
                    widget.vehicle.licensePlate,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF92400E),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              clientName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _loadVehicleRecords,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDBEAFE)),
                  ),
                  child: const Icon(
                    Icons.refresh_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildModernBottomNav(),
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
              : Column(
                  children: [
                    _buildTopCapsuleSelector(),
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const BouncingScrollPhysics(),
                        onPageChanged: (index) {
                          setState(() => _selectedIndex = index);
                        },
                        children: [
                          // Tab 1: Estado del Vehículo & Timeline
                          _buildTimelineTab(currentStep),

                          // Tab 2: Ficha Técnica de Recepción
                          _buildRecepcionTab(),

                          // Tab 3: Informe de Peritaje con IA Gemini
                          _buildPeritajeTab(),

                          // Tab 4: Presupuesto & Costos
                          _buildPresupuestoTab(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // SELECTOR SUPERIOR: CÁPSULAS / PILLS MODERNAS
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildTopCapsuleSelector() {
    final items = [
      {
        'title': 'Progreso',
        'icon': Icons.timeline_rounded,
        'badge': null,
      },
      {
        'title': 'Recepción',
        'icon': Icons.assignment_turned_in_rounded,
        'badge': _recepcion != null ? 'Listo' : null,
        'badgeColor': const Color(0xFF10B981),
      },
      {
        'title': 'Peritaje IA',
        'icon': Icons.psychology_rounded,
        'badge': _peritaje != null ? 'IA' : null,
        'badgeColor': const Color(0xFF8B5CF6),
      },
      {
        'title': 'Presupuesto',
        'icon': Icons.request_quote_rounded,
        'badge': _cotizacion != null ? '\$' : null,
        'badgeColor': const Color(0xFF059669),
      },
    ];

    return Container(
      height: 52,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1.2),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = _selectedIndex == index;
          final badge = item['badge'] as String?;
          final badgeColor = (item['badgeColor'] as Color?) ?? AppColors.primary;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _goToPage(index),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      size: 16,
                      color: isSelected ? Colors.white : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item['title'] as String,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFF475569),
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.25)
                              : badgeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isSelected ? Colors.white : badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // BARRA DE NAVEGACIÓN INFERIOR ERGONÓMICA
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildModernBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
        border: const Border(
          top: BorderSide(color: Color(0xFFF1F5F9), width: 1.2),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavItem(
                index: 0,
                icon: Icons.timeline_rounded,
                label: 'Progreso',
              ),
              _buildBottomNavItem(
                index: 1,
                icon: Icons.assignment_turned_in_rounded,
                label: 'Recepción',
                isCompleted: _recepcion != null,
              ),
              _buildBottomNavItem(
                index: 2,
                icon: Icons.psychology_rounded,
                label: 'Peritaje IA',
                isCompleted: _peritaje != null,
              ),
              _buildBottomNavItem(
                index: 3,
                icon: Icons.request_quote_rounded,
                label: 'Presupuesto',
                isCompleted: _cotizacion != null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required int index,
    required IconData icon,
    required String label,
    bool isCompleted = false,
  }) {
    final isSelected = _selectedIndex == index;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _goToPage(index),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: isSelected ? 14 : 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color: isSelected ? AppColors.primary : const Color(0xFF94A3B8),
                  ),
                  if (isCompleted)
                    Positioned(
                      top: -2,
                      right: -4,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
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

            // Acceso Rápido a Módulos y Documentos
            _buildQuickAccessCards(),
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
      return _buildEmptyState(
        icon: Icons.psychology_outlined,
        iconColor: const Color(0xFF7E22CE),
        bgColor: const Color(0xFFFAF5FF),
        title: 'Sin peritaje técnico registrado aún',
        message:
            'El equipo técnico del taller generará la evaluación multimodal con IA Gemini próximamente para inspeccionar daños en carrocería.',
        actionLabel: 'Ver Ficha de Recepción',
        onAction: () => _goToPage(1),
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
      return _buildEmptyState(
        icon: Icons.assignment_outlined,
        iconColor: const Color(0xFF0284C7),
        bgColor: const Color(0xFFF0F9FF),
        title: 'Sin ficha de recepción activa',
        message:
            'No se ha registrado una orden de entrada o inventario oficial para este vehículo en el sistema.',
        actionLabel: 'Ver Estado del Progreso',
        onAction: () => _goToPage(0),
      );
    }

    final rec = _recepcion!;
    final hasSignature = _recepcionSignatureBytes != null ||
        (rec.clientSignature != null && rec.clientSignature!.isNotEmpty);

    final clientName = rec.ownerName ?? widget.client?.nombre ?? widget.vehicle.clientName ?? 'Cliente';
    final clientTaxId = rec.ownerTaxId ?? widget.client?.ci ?? '-';
    final clientPhone = rec.phone ?? widget.client?.telefono ?? '-';
    final clientAddress = rec.address ?? widget.client?.direccion ?? 'EN SITIO';

    final vehiclePlate = rec.licensePlate ?? widget.vehicle.licensePlate;
    final vehicleBrandModel = '${rec.brand ?? widget.vehicle.brand ?? ''} ${rec.model ?? widget.vehicle.model ?? ''}'.trim();
    final vehicleColor = rec.color ?? widget.vehicle.color ?? '-';
    final vehicleMileage = rec.mileage ?? '-';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Encabezado Oficial del Taller
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
                            width: 44,
                            height: 44,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/logo-taller-360.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'TALLER INTEGRALE\$ 360 GARAGE C.A.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                'MECÁNICA GENERAL • LATONERÍA Y PINTURA',
                                style: TextStyle(fontSize: 9.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                              ),
                              Text(
                                'RIF: J-50123456-7 • Telf: (0212) 555-0360',
                                style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'FICHA DE CONTROL E INSPECCIÓN DE RECEPCIÓN DE VEHÍCULO',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFBAE6FD)),
                        ),
                        child: Text(
                          'N° ${rec.code}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0369A1),
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Fecha Entrada: ${rec.entryDate ?? '-'}',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                          ),
                          if (rec.exitDate != null)
                            Text(
                              'Fecha Est. Salida: ${rec.exitDate}',
                              style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 2. Datos del Propietario / Cliente y Vehículo
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DATOS DEL PROPIETARIO / CLIENTE',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: 0.3),
                  ),
                  const Divider(color: Color(0xFFF1F5F9), height: 12),
                  _specRow('Nombre/Razón:', clientName),
                  _specRow('C.I. / RIF:', clientTaxId),
                  _specRow('Teléfono:', clientPhone),
                  _specRow('Dirección:', clientAddress),
                  const SizedBox(height: 12),
                  const Text(
                    'DATOS DEL VEHÍCULO',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: 0.3),
                  ),
                  const Divider(color: Color(0xFFF1F5F9), height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Placa:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Text(
                          vehiclePlate,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF92400E)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _specRow('Marca / Modelo:', vehicleBrandModel.isNotEmpty ? vehicleBrandModel : '-'),
                  _specRow('Color:', vehicleColor),
                  _specRow('Kilometraje:', '$vehicleMileage km'),
                  if (rec.vin != null && rec.vin!.isNotEmpty)
                    _specRow('VIN / Serial:', rec.vin!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 3. Custodia y Personal Responsable
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CUSTODIA Y PERSONAL RESPONSABLE',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: 0.3),
                  ),
                  const Divider(color: Color(0xFFF1F5F9), height: 12),
                  _specRow('Recibido por:', rec.receivedBy != null && rec.receivedBy!.isNotEmpty ? rec.receivedBy! : '-'),
                  _specRow('Entregado por:', rec.deliveredBy != null && rec.deliveredBy!.isNotEmpty ? rec.deliveredBy! : clientName),
                  _specRow('Técnico Asignado:', rec.assignedTechnician != null && rec.assignedTechnician!.isNotEmpty ? rec.assignedTechnician! : 'YEISON TORRES'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 4. Nivel de Combustible & Motivo de Ingreso
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFuelGauge(rec.fuelLevel),
                  const SizedBox(height: 14),
                  const Text(
                    'MOTIVO DE INGRESO / FALLAS REPORTADAS',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: 0.3),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      rec.reasonForEntry != null && rec.reasonForEntry!.isNotEmpty
                          ? rec.reasonForEntry!
                          : (rec.observations != null && rec.observations!.isNotEmpty
                              ? rec.observations!
                              : 'Ingreso regular a taller para revisión.'),
                      style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B), height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 5. Diagrama de Carrocería y Daños
          _buildDamagePointsSection(rec.damagePoints),
          const SizedBox(height: 14),

          // 6. Inventario de Componentes y Estado Físico (Checklist)
          _buildChecklistSection(
            title: 'Revisión Externa (Carrocería / Cristales / Luces / Ruedas)',
            items: rec.checklistExternal,
            emptyMessage: 'Todos los componentes externos verificados OK.',
          ),
          const SizedBox(height: 14),

          _buildChecklistSection(
            title: 'Revisión Interna (Habitáculo / Mandos / Auxilio)',
            items: rec.checklistInternal,
            emptyMessage: 'Todos los componentes internos verificados OK.',
          ),
          const SizedBox(height: 14),

          // 7. Servicios y Reparaciones Aprobadas (si existen)
          if (rec.authorizedServices != null && rec.authorizedServices!.isNotEmpty) ...[
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SERVICIOS Y REPARACIONES APROBADAS A REALIZAR',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: 0.3),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      rec.authorizedServices!,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // 8. Cláusula Legal de Custodia
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Text(
              'CLÁUSULA DE CUSTODIA Y CONFORMIDAD: El cliente autoriza los trabajos mencionados y los desplazamientos necesarios para pruebas mecánicas bajo su cuenta y riesgo. El taller no se hace responsable por pérdidas de objetos de valor o dinero no especificados en este reporte. Todo trabajo adicional no contemplado requerirá previa autorización.',
              style: TextStyle(fontSize: 10, color: Color(0xFF64748B), height: 1.35),
              textAlign: TextAlign.justify,
            ),
          ),
          const SizedBox(height: 16),

          // 9. Bloques de Firmas Digitales
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
                                  : 'Firme para validar el inventario oficial del vehículo.',
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
                      height: 56,
                      width: double.infinity,
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

          // 10. Botones de Acción
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
      return _buildEmptyState(
        icon: Icons.request_quote_outlined,
        iconColor: const Color(0xFF059669),
        bgColor: const Color(0xFFECFDF5),
        title: 'Sin presupuesto emitido por el momento',
        message:
            'Una vez completado el peritaje técnico, el taller generará la cotización de repuestos y mano de obra para su aprobación.',
        actionLabel: 'Ver Informe Peritaje IA',
        onAction: () => _goToPage(2),
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

  // ──────────────────────────────────────────────────────────────────────────
  // Accesos Rápidos a Módulos y Documentos (Dashboard)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildQuickAccessCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Documentos & Evaluaciones',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                'Toca para explorar',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // Card 1: Recepción
            Expanded(
              child: _buildQuickCardItem(
                title: 'Recepción',
                subtitle: _recepcion != null ? 'Ficha Lista ✓' : 'Pendiente',
                icon: Icons.assignment_turned_in_rounded,
                color: const Color(0xFF0284C7),
                bgColor: const Color(0xFFF0F9FF),
                onTap: () => _goToPage(1),
              ),
            ),
            const SizedBox(width: 8),
            // Card 2: Peritaje IA
            Expanded(
              child: _buildQuickCardItem(
                title: 'Peritaje IA',
                subtitle: _peritaje != null ? 'IA Lista ✓' : 'En espera',
                icon: Icons.psychology_rounded,
                color: const Color(0xFF7E22CE),
                bgColor: const Color(0xFFFAF5FF),
                onTap: () => _goToPage(2),
              ),
            ),
            const SizedBox(width: 8),
            // Card 3: Presupuesto
            Expanded(
              child: _buildQuickCardItem(
                title: 'Presupuesto',
                subtitle: _cotizacion != null
                    ? '\$${_cotizacion!.total.toStringAsFixed(2)}'
                    : 'En revisión',
                icon: Icons.request_quote_rounded,
                color: const Color(0xFF059669),
                bgColor: const Color(0xFFECFDF5),
                onTap: () => _goToPage(3),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickCardItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.25), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Estado Vacío Moderno y Elegante
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildEmptyState({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 48, color: iconColor),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: Text(actionLabel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: iconColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Medidor Gráfico de Combustible
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildFuelGauge(String? fuelLevel) {
    final fuel = fuelLevel?.trim() ?? '1/2';
    double percentage = 0.5;
    Color barColor = const Color(0xFF10B981);
    if (fuel.contains('Reserva') || fuel == 'E') {
      percentage = 0.1;
      barColor = const Color(0xFFEF4444);
    } else if (fuel.contains('1/4')) {
      percentage = 0.25;
      barColor = const Color(0xFFF59E0B);
    } else if (fuel.contains('1/2')) {
      percentage = 0.50;
      barColor = const Color(0xFF10B981);
    } else if (fuel.contains('3/4')) {
      percentage = 0.75;
      barColor = const Color(0xFF059669);
    } else if (fuel.contains('F') || fuel.contains('Lleno') || fuel == '1/1' || fuel == '1') {
      percentage = 1.0;
      barColor = const Color(0xFF2563EB);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Nivel de Combustible',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_gas_station_rounded, size: 14, color: Color(0xFF2563EB)),
                  const SizedBox(width: 4),
                  Text(
                    fuel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Container(
            height: 10,
            width: double.infinity,
            color: const Color(0xFFE2E8F0),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage,
              child: Container(
                color: barColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('E (Reserva)', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
            Text('1/4', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
            Text('1/2', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
            Text('3/4', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
            Text('F (Lleno)', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
          ],
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Diagrama de Estado de Carrocería y Daños
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildDamagePointsSection(List<Map<String, dynamic>> damagePoints) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'DIAGRAMA DE CARROCERÍA Y DAÑOS (${damagePoints.length} MARCAS)',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                Wrap(
                  spacing: 4,
                  children: const [
                    Text('R: Rayón', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                    Text('G: Golpe', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                    Text('Q: Quebrado', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED))),
                    Text('F: Falta', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (damagePoints.isNotEmpty) ...[
              Column(
                children: damagePoints.map((pt) {
                  final type = pt['type']?.toString().toLowerCase() ?? 'scratch';
                  Color color = const Color(0xFFD97706);
                  String letter = 'R';
                  if (type == 'dent' || type == 'golpe') {
                    color = const Color(0xFFDC2626);
                    letter = 'G';
                  } else if (type == 'broken' || type == 'quebrado') {
                    color = const Color(0xFF7C3AED);
                    letter = 'Q';
                  } else if (type == 'missing' || type == 'falta') {
                    color = const Color(0xFF2563EB);
                    letter = 'F';
                  }

                  final view = pt['view']?.toString() ?? 'front';
                  final notes = pt['notes']?.toString() ?? 'Detalle no especificado';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            letter,
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Vista $view:'.toUpperCase(),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            notes,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Text(
                  'No se registraron daños visuales. El vehículo se recibe con carrocería en buen estado general.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF64748B)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Inventario de Componentes y Estado Físico
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildChecklistSection({
    required String title,
    required List<Map<String, dynamic>> items,
    required String emptyMessage,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 10),
            if (items.isNotEmpty) ...[
              for (final item in items) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item['name']?.toString() ?? 'Componente',
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF1E293B), fontWeight: FontWeight.w500),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (item['notes'] != null && item['notes'].toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Text(
                                '(${item['notes']})',
                                style: const TextStyle(fontSize: 10, color: Color(0xFFDC2626)),
                              ),
                            ),
                          _buildStatusBadge(item['status']?.toString().toLowerCase()),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(color: Color(0xFFF1F5F9), height: 8),
              ],
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  emptyMessage,
                  style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF64748B)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String? status) {
    Color bg = const Color(0xFFE2E8F0);
    Color text = const Color(0xFF475569);
    String label = 'N/A';

    if (status == 'ok' || status == 'bueno' || status == 'conforme') {
      bg = const Color(0xFFDCFCE7);
      text = const Color(0xFF166534);
      label = 'OK';
    } else if (status == 'bad' || status == 'mal' || status == 'dañado') {
      bg = const Color(0xFFFEE2E2);
      text = const Color(0xFF991B1B);
      label = 'MAL';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: text),
      ),
    );
  }
}
