import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/permisos/permisos_service.dart';
import '../../../config/usuario_config.dart';

class PermisosScreen extends StatefulWidget {
  const PermisosScreen({super.key});

  @override
  State<PermisosScreen> createState() => _PermisosScreenState();
}

class _PermisosScreenState extends State<PermisosScreen> {
  final _service = PermisosService();

  MisPermisosModel? _datos;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final datos =
    await _service.obtenerMisPermisos(UsuarioConfig.usuarioId);
    setState(() {
      _datos = datos;
      _cargando = false;
    });
  }

  Color _colorEstado(int estado) {
    switch (estado) {
      case 0: return const Color(0xFFFF6B35);
      case 1: return const Color(0xFF00B37E);
      case 2: return const Color(0xFFF32836);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text('Permisos',
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
            onPressed: _abrirNuevoPermiso,
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _cargar,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildResumen()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Row(
                  children: [
                    Text('Mis solicitudes',
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A2E))),
                    const Spacer(),
                    if ((_datos?.permisos.length ?? 0) > 0)
                      Text(
                        '${_datos!.permisos.length} ${_datos!.permisos.length == 1 ? "solicitud" : "solicitudes"}',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[500]),
                      ),
                  ],
                ),
              ),
            ),
            _buildListaPermisos(),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirNuevoPermiso,
        backgroundColor: const Color(0xFF005DB9),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Nuevo permiso',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildResumen() {
    final total = _datos?.totalHorasAprobadasMes ?? 0;
    final pendientes = _datos?.permisos
        .where((p) => p.estado == 0)
        .length ?? 0;
    final aprobados = _datos?.permisos
        .where((p) => p.estado == 1)
        .length ?? 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7B61FF), Color(0xFF9B89FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7B61FF).withOpacity(0.3),
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
                child: const Icon(Icons.event_note_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Horas aprobadas este mes',
                      style: GoogleFonts.poppins(
                          color: Colors.white70, fontSize: 12)),
                  Text(
                    _formatearHoras(total),
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 26,
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
                child: _MiniStatPermiso(
                  valor: '$pendientes',
                  etiqueta: 'Pendientes',
                  icono: Icons.hourglass_empty_rounded,
                ),
              ),
              Container(
                  width: 1,
                  height: 36,
                  color: Colors.white.withOpacity(0.2)),
              Expanded(
                child: _MiniStatPermiso(
                  valor: '$aprobados',
                  etiqueta: 'Aprobados',
                  icono: Icons.check_circle_outline_rounded,
                ),
              ),
              Container(
                  width: 1,
                  height: 36,
                  color: Colors.white.withOpacity(0.2)),
              Expanded(
                child: _MiniStatPermiso(
                  valor:
                  '${_datos?.permisos.where((p) => p.estado == 2).length ?? 0}',
                  etiqueta: 'Rechazados',
                  icono: Icons.cancel_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListaPermisos() {
    final permisos = _datos?.permisos ?? [];

    if (permisos.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                Icon(Icons.event_note_outlined,
                    size: 64, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text('Sin solicitudes de permisos',
                    style: GoogleFonts.poppins(
                        color: Colors.grey[400], fontSize: 15)),
                const SizedBox(height: 8),
                Text('Toca + para crear una nueva',
                    style: GoogleFonts.poppins(
                        color: Colors.grey[400], fontSize: 13)),
              ],
            ),
          ),
        ),
      );
    }

    final ordenados = [...permisos]
      ..sort((a, b) => b.fechaSolicitud.compareTo(a.fechaSolicitud));

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, i) => _TarjetaPermiso(
          permiso: ordenados[i],
          colorEstado: _colorEstado(ordenados[i].estado),
          onTap: () => _verDetalle(ordenados[i]),
        ),
        childCount: ordenados.length,
      ),
    );
  }

  void _verDetalle(PermisoModel permiso) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ModalDetallePermiso(
        permiso: permiso,
        colorEstado: _colorEstado(permiso.estado),
      ),
    );
  }

  void _abrirNuevoPermiso() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ModalNuevoPermiso(
        onCrear: (fecha, horaInicio, horaFin, motivo) async {
          final ok = await _service.crearPermiso(
            colaboradorId: UsuarioConfig.usuarioId,
            fecha: fecha,
            horaInicio: horaInicio,
            horaFin: horaFin,
            motivo: motivo,
          );
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              ok
                  ? 'Permiso solicitado correctamente'
                  : 'Error al enviar la solicitud',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor:
            ok ? const Color(0xFF00B37E) : const Color(0xFFF32836),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ));
          if (ok) _cargar();
        },
      ),
    );
  }

  String _formatearHoras(double h) {
    final horas = h.toInt();
    final minutos = ((h - horas) * 60).toInt();
    if (minutos == 0) return '${horas}h';
    return '${horas}h ${minutos}min';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TARJETA PERMISO
// ─────────────────────────────────────────────────────────────────────────────

class _TarjetaPermiso extends StatelessWidget {
  final PermisoModel permiso;
  final Color colorEstado;
  final VoidCallback onTap;

  const _TarjetaPermiso({
    required this.permiso,
    required this.colorEstado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
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
            // Icono
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFF7B61FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.event_note_rounded,
                  color: Color(0xFF7B61FF), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          permiso.motivo.isNotEmpty
                              ? permiso.motivo
                              : 'Sin motivo',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: const Color(0xFF1A1A2E)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _PillEstado(
                          texto: permiso.etiquetaEstado,
                          color: colorEstado),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 12, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        _fmtFecha(permiso.fecha),
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: Colors.grey[500]),
                      ),
                      const SizedBox(width: 10),
                      Icon(Icons.schedule_rounded,
                          size: 12, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        '${_fmtHora(permiso.horaInicio)} — ${_fmtHora(permiso.horaFin)}',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  permiso.horasTexto,
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF7B61FF)),
                ),
                Text('horas',
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: Colors.grey[400])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmtFecha(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _fmtHora(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

// ─────────────────────────────────────────────────────────────────────────────
// MODAL DETALLE
// ─────────────────────────────────────────────────────────────────────────────

class _ModalDetallePermiso extends StatelessWidget {
  final PermisoModel permiso;
  final Color colorEstado;

  const _ModalDetallePermiso({
    required this.permiso,
    required this.colorEstado,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Row(
              children: [
                Expanded(
                  child: Text('Detalle del permiso',
                      style: GoogleFonts.poppins(
                          fontSize: 20, fontWeight: FontWeight.w700)),
                ),
                _PillEstado(
                    texto: permiso.etiquetaEstado, color: colorEstado),
              ],
            ),
            const SizedBox(height: 20),
            _FilaDetalle(
              icono: Icons.comment_outlined,
              etiqueta: 'Motivo',
              valor: permiso.motivo.isNotEmpty
                  ? permiso.motivo
                  : 'Sin motivo especificado',
            ),
            const SizedBox(height: 12),
            _FilaDetalle(
              icono: Icons.calendar_today_rounded,
              etiqueta: 'Fecha',
              valor: _fmtFechaCompleta(permiso.fecha),
            ),
            const SizedBox(height: 12),
            _FilaDetalle(
              icono: Icons.schedule_rounded,
              etiqueta: 'Horario',
              valor:
              '${_fmtHora(permiso.horaInicio)} — ${_fmtHora(permiso.horaFin)} · ${permiso.horasTexto}',
            ),
            const SizedBox(height: 12),
            _FilaDetalle(
              icono: Icons.access_time_rounded,
              etiqueta: 'Fecha de solicitud',
              valor: _fmtFechaCompleta(permiso.fechaSolicitud),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtFechaCompleta(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _fmtHora(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

// ─────────────────────────────────────────────────────────────────────────────
// MODAL NUEVO PERMISO
// ─────────────────────────────────────────────────────────────────────────────

class _ModalNuevoPermiso extends StatefulWidget {
  final Future<void> Function(
      DateTime fecha,
      DateTime horaInicio,
      DateTime horaFin,
      String motivo,
      ) onCrear;

  const _ModalNuevoPermiso({required this.onCrear});

  @override
  State<_ModalNuevoPermiso> createState() => _ModalNuevoPermisoState();
}

class _ModalNuevoPermisoState extends State<_ModalNuevoPermiso> {
  final _motivoCtrl = TextEditingController();

  DateTime _fecha = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _horaInicio = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _horaFin = const TimeOfDay(hour: 10, minute: 0);
  bool _enviando = false;

  @override
  void dispose() {
    _motivoCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (fecha != null) setState(() => _fecha = fecha);
  }

  Future<void> _seleccionarHoraInicio() async {
    final hora =
    await showTimePicker(context: context, initialTime: _horaInicio);
    if (hora != null) setState(() => _horaInicio = hora);
  }

  Future<void> _seleccionarHoraFin() async {
    final hora =
    await showTimePicker(context: context, initialTime: _horaFin);
    if (hora != null) setState(() => _horaFin = hora);
  }

  DateTime _combinar(DateTime fecha, TimeOfDay hora) => DateTime(
    fecha.year,
    fecha.month,
    fecha.day,
    hora.hour,
    hora.minute,
  );

  double get _horasTotales {
    final inicio = _horaInicio.hour * 60 + _horaInicio.minute;
    final fin = _horaFin.hour * 60 + _horaFin.minute;
    final diff = fin - inicio;
    return diff > 0 ? diff / 60.0 : 0;
  }

  Future<void> _enviar() async {
    if (_motivoCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Escribe el motivo del permiso',
            style: GoogleFonts.poppins()),
        backgroundColor: const Color(0xFFF32836),
      ));
      return;
    }
    if (_horasTotales <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('La hora de fin debe ser mayor a la de inicio',
            style: GoogleFonts.poppins()),
        backgroundColor: const Color(0xFFF32836),
      ));
      return;
    }

    setState(() => _enviando = true);
    Navigator.pop(context);
    await widget.onCrear(
      _fecha,
      _combinar(_fecha, _horaInicio),
      _combinar(_fecha, _horaFin),
      _motivoCtrl.text.trim(),
    );
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
            Text('Solicitar permiso',
                style: GoogleFonts.poppins(
                    fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),

            // Fecha
            Text('Fecha',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.grey[600])),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _seleccionarFecha,
              child: _CampoSeleccion(
                icono: Icons.calendar_today_rounded,
                valor:
                '${_fecha.day.toString().padLeft(2, '0')}/${_fecha.month.toString().padLeft(2, '0')}/${_fecha.year}',
              ),
            ),
            const SizedBox(height: 16),

            // Horario
            Text('Horario',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.grey[600])),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _seleccionarHoraInicio,
                    child: _CampoSeleccion(
                      icono: Icons.schedule_rounded,
                      valor:
                      '${_horaInicio.hour.toString().padLeft(2, '0')}:${_horaInicio.minute.toString().padLeft(2, '0')}',
                      etiqueta: 'Inicio',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _seleccionarHoraFin,
                    child: _CampoSeleccion(
                      icono: Icons.schedule_rounded,
                      valor:
                      '${_horaFin.hour.toString().padLeft(2, '0')}:${_horaFin.minute.toString().padLeft(2, '0')}',
                      etiqueta: 'Fin',
                    ),
                  ),
                ),
              ],
            ),

            // Resumen horas
            if (_horasTotales > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:
                  const Color(0xFF7B61FF).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 14, color: Color(0xFF7B61FF)),
                    const SizedBox(width: 8),
                    Text(
                      'Total: ${_formatearHoras(_horasTotales)}',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF7B61FF),
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Motivo
            Text('Motivo',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.grey[600])),
            const SizedBox(height: 8),
            TextField(
              controller: _motivoCtrl,
              maxLines: 3,
              style: GoogleFonts.poppins(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Describe el motivo de tu permiso...',
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

            // Botón
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _enviando ? null : _enviar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B61FF),
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
                    : Text('Enviar solicitud',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _formatearHoras(double h) {
    final horas = h.toInt();
    final minutos = ((h - horas) * 60).toInt();
    if (minutos == 0) return '${horas}h';
    return '${horas}h ${minutos}min';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGETS AUXILIARES
// ─────────────────────────────────────────────────────────────────────────────

class _PillEstado extends StatelessWidget {
  final String texto;
  final Color color;
  const _PillEstado({required this.texto, required this.color});

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

class _MiniStatPermiso extends StatelessWidget {
  final String valor;
  final String etiqueta;
  final IconData icono;
  const _MiniStatPermiso(
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
        Icon(icono, size: 18, color: const Color(0xFF7B61FF)),
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

class _CampoSeleccion extends StatelessWidget {
  final IconData icono;
  final String valor;
  final String? etiqueta;
  const _CampoSeleccion(
      {required this.icono, required this.valor, this.etiqueta});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icono, size: 16, color: const Color(0xFF7B61FF)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (etiqueta != null)
                  Text(etiqueta!,
                      style: GoogleFonts.poppins(
                          fontSize: 10, color: Colors.grey[400])),
                Text(valor,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1A1A2E))),
              ],
            ),
          ),
          Icon(Icons.keyboard_arrow_down_rounded,
              color: Colors.grey[400], size: 18),
        ],
      ),
    );
  }
}