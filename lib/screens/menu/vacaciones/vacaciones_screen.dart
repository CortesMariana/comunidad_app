import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/vacaciones/vacaciones_service.dart';
import '../../../config/usuario_config.dart';

class VacacionesScreen extends StatefulWidget {
  const VacacionesScreen({super.key});

  @override
  State<VacacionesScreen> createState() => _VacacionesScreenState();
}

class _VacacionesScreenState extends State<VacacionesScreen>
    with SingleTickerProviderStateMixin {
  final _service = VacacionesService();
  late TabController _tabController;

  List<SolicitudVacacionesModel> _solicitudes = [];
  ConteoVacacionesModel? _conteo;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargar();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final results = await Future.wait([
      _service.obtenerSolicitudes(UsuarioConfig.usuarioId),
      _service.obtenerConteo(UsuarioConfig.usuarioId),
    ]);
    setState(() {
      _solicitudes = results[0] as List<SolicitudVacacionesModel>;
      _conteo = results[1] as ConteoVacacionesModel?;
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text('Vacaciones',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Color(0xFF005DB9)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded,
                color: Color(0xFF005DB9)),
            onPressed: _abrirNuevaSolicitud,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelStyle:
          GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 13),
          labelColor: const Color(0xFF005DB9),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF005DB9),
          indicatorWeight: 2.5,
          tabs: const [
            Tab(text: 'Mis solicitudes'),
            Tab(text: 'Resumen'),
          ],
        ),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _cargar,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildTabSolicitudes(),
            _buildTabResumen(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirNuevaSolicitud,
        backgroundColor: const Color(0xFF005DB9),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Nueva solicitud',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ── TAB SOLICITUDES ───────────────────────────────────────────────────────

  Widget _buildTabSolicitudes() {
    if (_solicitudes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.beach_access_outlined,
                size: 64, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('Sin solicitudes aún',
                style: GoogleFonts.poppins(
                    color: Colors.grey[400], fontSize: 15)),
            const SizedBox(height: 8),
            Text('Toca + para crear una nueva',
                style: GoogleFonts.poppins(
                    color: Colors.grey[400], fontSize: 13)),
          ],
        ),
      );
    }

    // Ordenar: más recientes primero
    final ordenadas = [..._solicitudes]
      ..sort((a, b) => b.fechaSolicitud.compareTo(a.fechaSolicitud));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: ordenadas.length,
      itemBuilder: (context, i) => _TarjetaSolicitud(
        solicitud: ordenadas[i],
        onTap: () => _verDetalle(ordenadas[i]),
      ),
    );
  }

  // ── TAB RESUMEN ───────────────────────────────────────────────────────────

  Widget _buildTabResumen() {
    final conteo = _conteo;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Card de días disponibles
          _buildCardDias(conteo),
          const SizedBox(height: 16),

          // Solicitudes por estatus
          _buildResumenEstatus(),
          const SizedBox(height: 16),

          // Historial compacto
          _buildHistorialCompacto(),
        ],
      ),
    );
  }

  Widget _buildCardDias(ConteoVacacionesModel? conteo) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF005DB9), Color(0xFF009BDF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF005DB9).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.beach_access_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Días disfrutados',
                      style: GoogleFonts.poppins(
                          color: Colors.white70, fontSize: 13)),
                  Text(
                    '${conteo?.descansados ?? 0} días',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniStatVac(
                  valor: '${conteo?.solicitados ?? 0}',
                  etiqueta: 'Solicitados',
                  icono: Icons.hourglass_empty_rounded,
                ),
              ),
              Container(
                  width: 1,
                  height: 36,
                  color: Colors.white.withOpacity(0.2)),
              Expanded(
                child: _MiniStatVac(
                  valor: '${conteo?.aprobados ?? 0}',
                  etiqueta: 'Aprobados',
                  icono: Icons.check_circle_outline_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResumenEstatus() {
    final pendientes =
        _solicitudes.where((s) => s.estatus == 1).length;
    final aprobadas =
        _solicitudes.where((s) => s.estatus == 2).length;
    final rechazadas =
        _solicitudes.where((s) => s.estatus == 3).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Por estatus',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: const Color(0xFF1A1A2E))),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _EstatusItem(
                  valor: '$pendientes',
                  etiqueta: 'Pendientes',
                  color: const Color(0xFFFF6B35),
                  icono: Icons.schedule_rounded,
                ),
              ),
              Expanded(
                child: _EstatusItem(
                  valor: '$aprobadas',
                  etiqueta: 'Aprobadas',
                  color: const Color(0xFF00B37E),
                  icono: Icons.check_circle_rounded,
                ),
              ),
              Expanded(
                child: _EstatusItem(
                  valor: '$rechazadas',
                  etiqueta: 'Rechazadas',
                  color: const Color(0xFFF32836),
                  icono: Icons.cancel_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistorialCompacto() {
    final recientes = [..._solicitudes]
      ..sort((a, b) => b.fechaSolicitud.compareTo(a.fechaSolicitud));
    final top = recientes.take(3).toList();

    if (top.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Recientes',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: const Color(0xFF1A1A2E))),
              const Spacer(),
              GestureDetector(
                onTap: () => _tabController.animateTo(0),
                child: Text('Ver todo',
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF005DB9),
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...top.map((s) => _FilaCompacta(solicitud: s,
              onTap: () => _verDetalle(s))),
        ],
      ),
    );
  }

  void _verDetalle(SolicitudVacacionesModel solicitud) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ModalDetalleSolicitud(solicitud: solicitud),
    );
  }

  void _abrirNuevaSolicitud() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ModalNuevaSolicitud(
        onCrear: (tipo, fechas, comentarios) async {
          final ok = await _service.crearSolicitud(
            empleadoId: UsuarioConfig.usuarioId,
            tipo: tipo,
            fechas: fechas,
            comentarios: comentarios,
          );
          if (ok && mounted) {
            _cargar();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Solicitud enviada correctamente',
                  style: GoogleFonts.poppins()),
              backgroundColor: const Color(0xFF00B37E),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ));
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Error al enviar la solicitud',
                  style: GoogleFonts.poppins()),
              backgroundColor: const Color(0xFFF32836),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ));
          }
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TARJETA SOLICITUD
// ─────────────────────────────────────────────────────────────────────────────

class _TarjetaSolicitud extends StatelessWidget {
  final SolicitudVacacionesModel solicitud;
  final VoidCallback onTap;

  const _TarjetaSolicitud(
      {required this.solicitud, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _colorEstatus(solicitud.estatus);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            // Icono tipo
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF009BDF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                solicitud.tipo == 1
                    ? Icons.beach_access_rounded
                    : Icons.person_off_rounded,
                color: const Color(0xFF009BDF),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(solicitud.etiquetaTipo,
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: const Color(0xFF1A1A2E))),
                      const SizedBox(width: 8),
                      _PillEstatus(
                          texto: solicitud.etiquetaEstatus,
                          color: color),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    solicitud.comentarios,
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[500]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatearFechas(solicitud.fechasSolicitadas),
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${solicitud.conteoDias}',
                    style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF005DB9))),
                Text(
                    solicitud.conteoDias == 1 ? 'día' : 'días',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.grey[400])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatearFechas(List<DateTime> fechas) {
    if (fechas.isEmpty) return '';
    if (fechas.length == 1) return _fmtFecha(fechas.first);
    return '${_fmtFecha(fechas.first)} — ${_fmtFecha(fechas.last)}';
  }

  String _fmtFecha(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Color _colorEstatus(int estatus) {
    switch (estatus) {
      case 1: return const Color(0xFFFF6B35);
      case 2: return const Color(0xFF00B37E);
      case 3: return const Color(0xFFF32836);
      default: return Colors.grey;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MODAL DETALLE
// ─────────────────────────────────────────────────────────────────────────────

class _ModalDetalleSolicitud extends StatelessWidget {
  final SolicitudVacacionesModel solicitud;
  const _ModalDetalleSolicitud({required this.solicitud});

  @override
  Widget build(BuildContext context) {
    final color = _colorEstatus(solicitud.estatus);

    return Container(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Row(
              children: [
                Expanded(
                  child: Text(solicitud.etiquetaTipo,
                      style: GoogleFonts.poppins(
                          fontSize: 20, fontWeight: FontWeight.w700)),
                ),
                _PillEstatus(
                    texto: solicitud.etiquetaEstatus, color: color),
              ],
            ),
            const SizedBox(height: 20),

            // Comentarios
            _FilaDetalle(
              icono: Icons.comment_outlined,
              etiqueta: 'Comentarios',
              valor: solicitud.comentarios,
            ),
            const SizedBox(height: 12),

            // Días
            _FilaDetalle(
              icono: Icons.calendar_today_rounded,
              etiqueta: 'Días solicitados',
              valor: '${solicitud.conteoDias} ${solicitud.conteoDias == 1 ? "día" : "días"}',
            ),
            const SizedBox(height: 12),

            // Fecha solicitud
            _FilaDetalle(
              icono: Icons.access_time_rounded,
              etiqueta: 'Fecha de solicitud',
              valor: _fmtFechaCompleta(solicitud.fechaSolicitud),
            ),
            const SizedBox(height: 16),

            // Fechas solicitadas
            Text('Fechas seleccionadas',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.grey[600])),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: solicitud.fechasSolicitadas
                  .map((f) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF005DB9).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _fmtFecha(f),
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF005DB9),
                      fontWeight: FontWeight.w500),
                ),
              ))
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Color _colorEstatus(int estatus) {
    switch (estatus) {
      case 1: return const Color(0xFFFF6B35);
      case 2: return const Color(0xFF00B37E);
      case 3: return const Color(0xFFF32836);
      default: return Colors.grey;
    }
  }

  String _fmtFecha(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _fmtFechaCompleta(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

// ─────────────────────────────────────────────────────────────────────────────
// MODAL NUEVA SOLICITUD
// ─────────────────────────────────────────────────────────────────────────────

class _ModalNuevaSolicitud extends StatefulWidget {
  final Future<void> Function(int tipo, List<DateTime> fechas,
      String comentarios) onCrear;

  const _ModalNuevaSolicitud({required this.onCrear});

  @override
  State<_ModalNuevaSolicitud> createState() => _ModalNuevaSolicitudState();
}

class _ModalNuevaSolicitudState extends State<_ModalNuevaSolicitud> {
  int _tipo = 1;
  final List<DateTime> _fechasSeleccionadas = [];
  final _comentariosCtrl = TextEditingController();
  bool _enviando = false;

  @override
  void dispose() {
    _comentariosCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es'),
    );
    if (fecha == null) return;
    if (_fechasSeleccionadas.any((f) =>
    f.year == fecha.year &&
        f.month == fecha.month &&
        f.day == fecha.day)) {
      setState(() => _fechasSeleccionadas
          .removeWhere((f) =>
      f.year == fecha.year &&
          f.month == fecha.month &&
          f.day == fecha.day));
    } else {
      setState(() => _fechasSeleccionadas.add(fecha));
      _fechasSeleccionadas.sort();
    }
  }

  Future<void> _enviar() async {
    if (_fechasSeleccionadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Selecciona al menos una fecha',
            style: GoogleFonts.poppins()),
        backgroundColor: const Color(0xFFF32836),
      ));
      return;
    }
    setState(() => _enviando = true);
    Navigator.pop(context);
    await widget.onCrear(
        _tipo, _fechasSeleccionadas, _comentariosCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text('Nueva solicitud',
                style: GoogleFonts.poppins(
                    fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),

            // Tipo
            Text('Tipo',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, fontSize: 13,
                    color: Colors.grey[600])),
            const SizedBox(height: 8),
            Row(
              children: [
                _BotonTipo(
                  etiqueta: '🏖️ Vacaciones',
                  activo: _tipo == 1,
                  onTap: () => setState(() => _tipo = 1),
                ),
                const SizedBox(width: 10),
                _BotonTipo(
                  etiqueta: '👤 Día personal',
                  activo: _tipo == 2,
                  onTap: () => setState(() => _tipo = 2),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Fechas
            Row(
              children: [
                Text('Fechas',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 13,
                        color: Colors.grey[600])),
                const Spacer(),
                GestureDetector(
                  onTap: _seleccionarFecha,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF005DB9).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.add_rounded,
                            size: 16, color: Color(0xFF005DB9)),
                        const SizedBox(width: 4),
                        Text('Agregar fecha',
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF005DB9),
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_fechasSeleccionadas.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('Sin fechas seleccionadas',
                    style: GoogleFonts.poppins(
                        color: Colors.grey[400], fontSize: 13),
                    textAlign: TextAlign.center),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _fechasSeleccionadas
                    .map((f) => GestureDetector(
                  onTap: () => setState(() =>
                      _fechasSeleccionadas.remove(f)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF005DB9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}',
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.close_rounded,
                            size: 14, color: Colors.white70),
                      ],
                    ),
                  ),
                ))
                    .toList(),
              ),
            const SizedBox(height: 16),

            // Comentarios
            Text('Comentarios',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, fontSize: 13,
                    color: Colors.grey[600])),
            const SizedBox(height: 8),
            TextField(
              controller: _comentariosCtrl,
              maxLines: 3,
              style: GoogleFonts.poppins(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Motivo de la solicitud...',
                hintStyle: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.grey[400]),
                filled: true,
                fillColor: const Color(0xFFF5F6FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Botón enviar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _enviando ? null : _enviar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005DB9),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _enviando
                    ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                    : Text(
                    'Enviar solicitud · ${_fechasSeleccionadas.length} ${_fechasSeleccionadas.length == 1 ? "día" : "días"}',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGETS AUXILIARES
// ─────────────────────────────────────────────────────────────────────────────

class _PillEstatus extends StatelessWidget {
  final String texto;
  final Color color;
  const _PillEstatus({required this.texto, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(texto,
          style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color)),
    );
  }
}

class _MiniStatVac extends StatelessWidget {
  final String valor;
  final String etiqueta;
  final IconData icono;
  const _MiniStatVac(
      {required this.valor,
        required this.etiqueta,
        required this.icono});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icono, color: Colors.white70, size: 18),
        const SizedBox(height: 4),
        Text(valor,
            style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
        Text(etiqueta,
            style: GoogleFonts.poppins(
                color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}

class _EstatusItem extends StatelessWidget {
  final String valor;
  final String etiqueta;
  final Color color;
  final IconData icono;
  const _EstatusItem(
      {required this.valor,
        required this.etiqueta,
        required this.color,
        required this.icono});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icono, color: color, size: 22),
        ),
        const SizedBox(height: 6),
        Text(valor,
            style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A2E))),
        Text(etiqueta,
            style: GoogleFonts.poppins(
                fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }
}

class _FilaCompacta extends StatelessWidget {
  final SolicitudVacacionesModel solicitud;
  final VoidCallback onTap;
  const _FilaCompacta({required this.solicitud, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _colorEstatus(solicitud.estatus);
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                solicitud.etiquetaTipo,
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
            Text(
              '${solicitud.conteoDias} ${solicitud.conteoDias == 1 ? "día" : "días"}',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: Colors.grey[500]),
            ),
            const SizedBox(width: 8),
            _PillEstatus(
                texto: solicitud.etiquetaEstatus, color: color),
          ],
        ),
      ),
    );
  }

  Color _colorEstatus(int estatus) {
    switch (estatus) {
      case 1: return const Color(0xFFFF6B35);
      case 2: return const Color(0xFF00B37E);
      case 3: return const Color(0xFFF32836);
      default: return Colors.grey;
    }
  }
}

class _FilaDetalle extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final String valor;
  const _FilaDetalle(
      {required this.icono,
        required this.etiqueta,
        required this.valor});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 18, color: const Color(0xFF005DB9)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(etiqueta,
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: Colors.grey[400])),
              Text(valor,
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1A1A2E))),
            ],
          ),
        ),
      ],
    );
  }
}

class _BotonTipo extends StatelessWidget {
  final String etiqueta;
  final bool activo;
  final VoidCallback onTap;
  const _BotonTipo(
      {required this.etiqueta,
        required this.activo,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: activo ? const Color(0xFF005DB9) : const Color(0xFFF5F6FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: activo ? const Color(0xFF005DB9) : Colors.grey[300]!,
            ),
          ),
          child: Text(
            etiqueta,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: activo ? FontWeight.w600 : FontWeight.normal,
              color: activo ? Colors.white : const Color(0xFF1A1A2E),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}