import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/autorizaciones/autorizaciones_service.dart';
import '../../../config/usuario_config.dart';

class AutorizacionesScreen extends StatefulWidget {
  const AutorizacionesScreen({super.key});

  @override
  State<AutorizacionesScreen> createState() => _AutorizacionesScreenState();
}

class _AutorizacionesScreenState extends State<AutorizacionesScreen>
    with SingleTickerProviderStateMixin {
  final _service = AutorizacionesService();
  late TabController _tabController;

  List<AutorizacionVacacionModel> _vacaciones = [];
  List<AutorizacionPermisoModel> _permisos = [];
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
      _service.obtenerVacacionesPendientes(UsuarioConfig.usuarioId),
      _service.obtenerPermisosPendientes(UsuarioConfig.usuarioId),
    ]);
    setState(() {
      _vacaciones = results[0] as List<AutorizacionVacacionModel>;
      _permisos = results[1] as List<AutorizacionPermisoModel>;
      _cargando = false;
    });
  }

  int get _totalPendientes => _vacaciones.length + _permisos.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text('Autorizaciones',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Color(0xFF005DB9)),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w600, fontSize: 13),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 13),
          labelColor: const Color(0xFF005DB9),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF005DB9),
          indicatorWeight: 2.5,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Vacaciones'),
                  if (_vacaciones.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _BadgeContador(count: _vacaciones.length),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Permisos'),
                  if (_permisos.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _BadgeContador(count: _permisos.length),
                  ],
                ],
              ),
            ),
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
            _buildTabVacaciones(),
            _buildTabPermisos(),
          ],
        ),
      ),
    );
  }

  // ── TAB VACACIONES ────────────────────────────────────────────────────────

  Widget _buildTabVacaciones() {
    if (_vacaciones.isEmpty) {
      return _buildVacio(
        icono: Icons.beach_access_outlined,
        mensaje: 'Sin solicitudes de vacaciones pendientes',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _vacaciones.length,
      itemBuilder: (context, i) => _TarjetaVacacion(
        solicitud: _vacaciones[i],
        onAprobar: () => _accionVacacion(_vacaciones[i], true),
        onRechazar: () => _accionVacacion(_vacaciones[i], false),
      ),
    );
  }

  // ── TAB PERMISOS ──────────────────────────────────────────────────────────

  Widget _buildTabPermisos() {
    if (_permisos.isEmpty) {
      return _buildVacio(
        icono: Icons.event_note_outlined,
        mensaje: 'Sin solicitudes de permisos pendientes',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _permisos.length,
      itemBuilder: (context, i) => _TarjetaPermiso(
        permiso: _permisos[i],
        onAprobar: () => _accionPermiso(_permisos[i], true),
        onRechazar: () => _accionPermiso(_permisos[i], false),
      ),
    );
  }

  // ── ACCIONES ──────────────────────────────────────────────────────────────

  Future<void> _accionVacacion(
      AutorizacionVacacionModel solicitud, bool aprobar) async {
    if (!aprobar) {
      final confirmado = await _confirmarRechazo(context);
      if (!confirmado) return;
    }

    final ok = await _service.determinarVacacion(
      solicitudId: solicitud.id,
      aprobar: aprobar,
      jefeId: UsuarioConfig.usuarioId,
    );

    if (!mounted) return;
    _mostrarResultado(ok, aprobar);
    if (ok) _cargar();
  }

  Future<void> _accionPermiso(
      AutorizacionPermisoModel permiso, bool aprobar) async {
    String comentario = '';

    if (!aprobar) {
      final resultado = await _mostrarDialogoComentario(context);
      if (resultado == null) return;
      comentario = resultado;
    }

    final ok = await _service.resolverPermiso(
      solicitudId: permiso.id,
      aprobar: aprobar,
      comentario: comentario,
    );

    if (!mounted) return;
    _mostrarResultado(ok, aprobar);
    if (ok) _cargar();
  }

  Future<bool> _confirmarRechazo(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Rechazar solicitud',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(
            '¿Estás seguro de que deseas rechazar esta solicitud?',
            style: GoogleFonts.poppins(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar',
                style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF32836),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Rechazar',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<String?> _mostrarDialogoComentario(BuildContext context) async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Rechazar permiso',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Escribe el motivo del rechazo:',
                style: GoogleFonts.poppins(fontSize: 14)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 3,
              style: GoogleFonts.poppins(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Motivo...',
                hintStyle: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.grey[400]),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text('Cancelar',
                style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF32836),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Rechazar',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    return result;
  }

  void _mostrarResultado(bool ok, bool aprobar) {
    final msg = ok
        ? (aprobar ? 'Solicitud aprobada' : 'Solicitud rechazada')
        : 'Error al procesar la solicitud';
    final color = ok
        ? (aprobar ? const Color(0xFF00B37E) : const Color(0xFFF32836))
        : Colors.grey;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins()),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Widget _buildVacio({required IconData icono, required String mensaje}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icono, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            mensaje,
            style: GoogleFonts.poppins(
                color: Colors.grey[400], fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text('Todo al día',
              style: GoogleFonts.poppins(
                  color: Colors.grey[400], fontSize: 13)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TARJETA VACACIÓN
// ─────────────────────────────────────────────────────────────────────────────

class _TarjetaVacacion extends StatelessWidget {
  final AutorizacionVacacionModel solicitud;
  final VoidCallback onAprobar;
  final VoidCallback onRechazar;

  const _TarjetaVacacion({
    required this.solicitud,
    required this.onAprobar,
    required this.onRechazar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          // ── Header ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _AvatarEmpleado(
                  foto: solicitud.empleado.fotografiaMiniatura,
                  iniciales: solicitud.empleado.iniciales,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        solicitud.empleado.nombreCompleto,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: const Color(0xFF1A1A2E)),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          _Pill(
                            texto: solicitud.etiquetaTipo,
                            color: const Color(0xFF009BDF),
                          ),
                          const SizedBox(width: 6),
                          _Pill(
                            texto: '${solicitud.conteoDias} ${solicitud.conteoDias == 1 ? "día" : "días"}',
                            color: const Color(0xFF005DB9),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Comentarios ────────────────────────────────────────────────
          if (solicitud.comentarios.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6FA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.comment_outlined,
                      size: 16, color: Colors.grey[400]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      solicitud.comentarios,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 10),

          // ── Fechas ────────────────────────────────────────────────────
          if (solicitud.dias.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: solicitud.dias
                    .map((d) => _ChipFecha(fecha: d))
                    .toList(),
              ),
            ),

          const SizedBox(height: 14),

          // ── Acciones ──────────────────────────────────────────────────
          _BotonesAccion(
            onAprobar: onAprobar,
            onRechazar: onRechazar,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TARJETA PERMISO
// ─────────────────────────────────────────────────────────────────────────────

class _TarjetaPermiso extends StatelessWidget {
  final AutorizacionPermisoModel permiso;
  final VoidCallback onAprobar;
  final VoidCallback onRechazar;

  const _TarjetaPermiso({
    required this.permiso,
    required this.onAprobar,
    required this.onRechazar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          // ── Header ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _AvatarTexto(iniciales: permiso.iniciales),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        permiso.colaborador,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: const Color(0xFF1A1A2E)),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          _Pill(
                            texto: 'Permiso',
                            color: const Color(0xFF7B61FF),
                          ),
                          const SizedBox(width: 6),
                          _Pill(
                            texto: permiso.horasTexto,
                            color: const Color(0xFF005DB9),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Info horario ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF7B61FF).withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule_rounded,
                      size: 16, color: const Color(0xFF7B61FF)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_fmtFecha(permiso.fecha)} · ${_fmtHora(permiso.horaInicio)} — ${_fmtHora(permiso.horaFin)}',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF7B61FF),
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ── Motivo ────────────────────────────────────────────────────
          if (permiso.motivo.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6FA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.comment_outlined,
                        size: 16, color: Colors.grey[400]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        permiso.motivo,
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 14),

          // ── Acciones ──────────────────────────────────────────────────
          _BotonesAccion(
            onAprobar: onAprobar,
            onRechazar: onRechazar,
          ),
        ],
      ),
    );
  }

  String _fmtFecha(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _fmtHora(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGETS AUXILIARES
// ─────────────────────────────────────────────────────────────────────────────

class _BotonesAccion extends StatelessWidget {
  final VoidCallback onAprobar;
  final VoidCallback onRechazar;

  const _BotonesAccion(
      {required this.onAprobar, required this.onRechazar});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[100]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton.icon(
              onPressed: onRechazar,
              icon: const Icon(Icons.close_rounded,
                  size: 18, color: Color(0xFFF32836)),
              label: Text('Rechazar',
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFF32836))),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(18)),
                ),
              ),
            ),
          ),
          Container(
              width: 1, height: 44, color: Colors.grey[100]),
          Expanded(
            child: TextButton.icon(
              onPressed: onAprobar,
              icon: const Icon(Icons.check_rounded,
                  size: 18, color: Color(0xFF00B37E)),
              label: Text('Aprobar',
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF00B37E))),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(18)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarEmpleado extends StatelessWidget {
  final String foto;
  final String iniciales;
  const _AvatarEmpleado(
      {required this.foto, required this.iniciales});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 22,
      backgroundImage: foto.isNotEmpty ? NetworkImage(foto) : null,
      backgroundColor: const Color(0xFF005DB9).withOpacity(0.1),
      child: foto.isEmpty
          ? Text(iniciales,
          style: GoogleFonts.poppins(
              color: const Color(0xFF005DB9),
              fontWeight: FontWeight.w700,
              fontSize: 13))
          : null,
    );
  }
}

class _AvatarTexto extends StatelessWidget {
  final String iniciales;
  const _AvatarTexto({required this.iniciales});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 22,
      backgroundColor: const Color(0xFF7B61FF).withOpacity(0.1),
      child: Text(iniciales,
          style: GoogleFonts.poppins(
              color: const Color(0xFF7B61FF),
              fontWeight: FontWeight.w700,
              fontSize: 13)),
    );
  }
}

class _Pill extends StatelessWidget {
  final String texto;
  final Color color;
  const _Pill({required this.texto, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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

class _ChipFecha extends StatelessWidget {
  final DateTime fecha;
  const _ChipFecha({required this.fecha});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF005DB9).withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}',
        style: GoogleFonts.poppins(
            fontSize: 11,
            color: const Color(0xFF005DB9),
            fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _BadgeContador extends StatelessWidget {
  final int count;
  const _BadgeContador({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: const BoxDecoration(
        color: Color(0xFFF32836),
        shape: BoxShape.circle,
      ),
      child: Text(
        '$count',
        style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w700),
      ),
    );
  }
}