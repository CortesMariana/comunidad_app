import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/vacantes/vacantes_service.dart';
import '../../../config/usuario_config.dart';

class VacantesScreen extends StatefulWidget {
  const VacantesScreen({super.key});

  @override
  State<VacantesScreen> createState() => _VacantesScreenState();
}

class _VacantesScreenState extends State<VacantesScreen>
    with SingleTickerProviderStateMixin {
  final _service = VacantesService();
  late TabController _tabController;

  OrganigramaModel? _organigrama;
  List<SolicitudVacanteModel> _solicitudes = [];
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
      _service.obtenerEquipo(UsuarioConfig.usuarioId),
      _service.obtenerMisSolicitudes(UsuarioConfig.usuarioId),
    ]);
    final org = results[0] as OrganigramaModel?;
    print('=== ORGANIGRAMA ===');
    print('jefeDirecto: ${org?.jefeDirecto?.nombreCompleto}');
    print('equipo count: ${org?.equipo.length}');
    for (final m in org?.equipo ?? []) {
      print('  miembro: ${m.nombreCompleto}');
    }
    setState(() {
      _organigrama = org;
      _solicitudes = results[1] as List<SolicitudVacanteModel>;
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text('Vacantes',
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
          tabs: const [
            Tab(text: 'Mi equipo'),
            Tab(text: 'Mis solicitudes'),
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
            _buildTabOrganigrama(),
            _buildTabSolicitudes(),
          ],
        ),
      ),
    );
  }

  // ── TAB ORGANIGRAMA ───────────────────────────────────────────────────────

  Widget _buildTabOrganigrama() {
    final org = _organigrama;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          // Jefe directo
          if (org?.jefeDirecto != null) ...[
            _buildNodoJefe(org!.jefeDirecto!),
            _buildConector(),
          ],

          // Yo
          _buildNodoYo(),

          // Equipo
          if (org?.equipo.isNotEmpty ?? false) ...[
            _buildConector(),
            _buildEquipo(org!.equipo),
          ],

          const SizedBox(height: 24),

          // Leyenda asistencia
          if (org?.equipo.isNotEmpty ?? false)
            _buildLeyenda(),
        ],
      ),
    );
  }

  Widget _buildNodoJefe(JefeDirectoModel jefe) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF005DB9), Color(0xFF009BDF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF005DB9).withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundImage: jefe.fotografiaMiniatura.isNotEmpty
                ? NetworkImage(jefe.fotografiaMiniatura)
                : null,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: jefe.fotografiaMiniatura.isEmpty
                ? Text(jefe.iniciales,
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16))
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(jefe.nombreCompleto,
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                Text('Jefe directo',
                    style: GoogleFonts.poppins(
                        color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('Superior',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildNodoYo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFF005DB9).withOpacity(0.4), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundImage: UsuarioConfig.avatarUsuario.isNotEmpty
                    ? NetworkImage(UsuarioConfig.avatarUsuario)
                    : null,
                backgroundColor:
                const Color(0xFF005DB9).withOpacity(0.1),
                child: UsuarioConfig.avatarUsuario.isEmpty
                    ? Text(
                    UsuarioConfig.nombreUsuario.isNotEmpty
                        ? UsuarioConfig.nombreUsuario[0]
                        .toUpperCase()
                        : '?',
                    style: GoogleFonts.poppins(
                        color: const Color(0xFF005DB9),
                        fontWeight: FontWeight.w700,
                        fontSize: 16))
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFF005DB9),
                    shape: BoxShape.circle,
                    border:
                    Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.star_rounded,
                      size: 8, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(UsuarioConfig.nombreUsuario,
                    style: GoogleFonts.poppins(
                        color: const Color(0xFF1A1A2E),
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                Text(UsuarioConfig.puestoUsuario,
                    style: GoogleFonts.poppins(
                        color: Colors.grey[500], fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF005DB9).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('Tú',
                style: GoogleFonts.poppins(
                    color: const Color(0xFF005DB9),
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildConector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Center(
        child: Container(
          width: 2,
          height: 28,
          color: const Color(0xFF005DB9).withOpacity(0.25),
        ),
      ),
    );
  }

  Widget _buildEquipo(List<MiembroEquipoModel> equipo) {
    if (equipo.length == 1) {
      return _TarjetaMiembro(miembro: equipo.first);
    }

    return Column(
      children: [
        // Línea horizontal superior
        Row(
          children: [
            const Expanded(child: SizedBox()),
            Container(
              height: 2,
              width: MediaQuery.of(context).size.width * 0.6,
              color: const Color(0xFF005DB9).withOpacity(0.2),
            ),
            const Expanded(child: SizedBox()),
          ],
        ),
        const SizedBox(height: 4),
        // Miembros en grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.4,
          ),
          itemCount: equipo.length,
          itemBuilder: (context, i) =>
              _TarjetaMiembro(miembro: equipo[i]),
        ),
      ],
    );
  }

  Widget _buildLeyenda() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ItemLeyenda(
              color: const Color(0xFF00B37E), texto: 'En oficina'),
          _ItemLeyenda(
              color: const Color(0xFFFF6B35), texto: 'Sin registro'),
          _ItemLeyenda(
              color: const Color(0xFF009BDF), texto: 'Salió'),
        ],
      ),
    );
  }

  // ── TAB SOLICITUDES ───────────────────────────────────────────────────────

  Widget _buildTabSolicitudes() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Botón solicitar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onTap: _abrirNuevaSolicitud,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF005DB9), Color(0xFF009BDF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF005DB9).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.work_outline_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Solicitar vacante',
                              style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
                          Text('Postúlate para un puesto interno',
                              style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        color: Colors.white70, size: 16),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Lista solicitudes
        if (_solicitudes.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.work_off_outlined,
                      size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text('Sin solicitudes aún',
                      style: GoogleFonts.poppins(
                          color: Colors.grey[400], fontSize: 15)),
                  const SizedBox(height: 6),
                  Text('Toca el botón de arriba para solicitar',
                      style: GoogleFonts.poppins(
                          color: Colors.grey[400], fontSize: 13)),
                ],
              ),
            ),
          )
        else ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text('Mis solicitudes',
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A2E))),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, i) =>
                    _TarjetaSolicitudVacante(solicitud: _solicitudes[i]),
                childCount: _solicitudes.length,
              ),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  void _abrirNuevaSolicitud() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ModalNuevaSolicitud(
        service: _service,
        onCrear: (puestoId, observaciones) async {
          final ok = await _service.crearSolicitud(
            puestoId: puestoId,
            solicitanteId: UsuarioConfig.usuarioId,
            observaciones: observaciones,
          );
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              ok
                  ? 'Solicitud enviada correctamente'
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
}

// ─────────────────────────────────────────────────────────────────────────────
// TARJETA MIEMBRO EQUIPO
// ─────────────────────────────────────────────────────────────────────────────

class _TarjetaMiembro extends StatelessWidget {
  final MiembroEquipoModel miembro;
  const _TarjetaMiembro({required this.miembro});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage:
                miembro.fotografiaMiniatura.isNotEmpty
                    ? NetworkImage(miembro.fotografiaMiniatura)
                    : null,
                backgroundColor:
                miembro.colorAsistencia.withOpacity(0.1),
                child: miembro.fotografiaMiniatura.isEmpty
                    ? Text(miembro.iniciales,
                    style: GoogleFonts.poppins(
                        color: miembro.colorAsistencia,
                        fontWeight: FontWeight.w700,
                        fontSize: 14))
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: miembro.colorAsistencia,
                    shape: BoxShape.circle,
                    border:
                    Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            miembro.nombre,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: const Color(0xFF1A1A2E)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: miembro.colorAsistencia.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              miembro.etiquetaAsistencia,
              style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: miembro.colorAsistencia),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TARJETA SOLICITUD VACANTE
// ─────────────────────────────────────────────────────────────────────────────

class _TarjetaSolicitudVacante extends StatelessWidget {
  final SolicitudVacanteModel solicitud;
  const _TarjetaSolicitudVacante({required this.solicitud});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF005DB9).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.work_outline_rounded,
                color: Color(0xFF005DB9), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(solicitud.puesto,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: const Color(0xFF1A1A2E))),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: solicitud.colorEstado.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    solicitud.etiquetaEstado,
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: solicitud.colorEstado),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MODAL NUEVA SOLICITUD
// ─────────────────────────────────────────────────────────────────────────────

class _ModalNuevaSolicitud extends StatefulWidget {
  final VacantesService service;
  final Future<void> Function(String puestoId, String observaciones) onCrear;

  const _ModalNuevaSolicitud(
      {required this.service, required this.onCrear});

  @override
  State<_ModalNuevaSolicitud> createState() =>
      _ModalNuevaSolicitudState();
}

class _ModalNuevaSolicitudState extends State<_ModalNuevaSolicitud> {
  final _observacionesCtrl = TextEditingController();

  List<PuestoModel> _puestos = [];
  PuestoModel? _puestoSeleccionado;
  bool _cargandoPuestos = true;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _cargarPuestos();
  }

  @override
  void dispose() {
    _observacionesCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarPuestos() async {
    final puestos = await widget.service.obtenerPuestos();
    setState(() {
      _puestos = puestos;
      _cargandoPuestos = false;
    });
  }

  Future<void> _enviar() async {
    if (_puestoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Selecciona un puesto',
            style: GoogleFonts.poppins()),
        backgroundColor: const Color(0xFFF32836),
      ));
      return;
    }
    setState(() => _enviando = true);
    Navigator.pop(context);
    await widget.onCrear(
      _puestoSeleccionado!.id,
      _observacionesCtrl.text.trim(),
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
            Text('Solicitar vacante',
                style: GoogleFonts.poppins(
                    fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),

            // Puesto
            Text('Puesto',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.grey[600])),
            const SizedBox(height: 8),
            _cargandoPuestos
                ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ))
                : Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<PuestoModel>(
                  value: _puestoSeleccionado,
                  isExpanded: true,
                  hint: Text('Selecciona un puesto',
                      style: GoogleFonts.poppins(
                          color: Colors.grey[400],
                          fontSize: 13)),
                  icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF005DB9)),
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF1A1A2E)),
                  items: _puestos
                      .map((p) => DropdownMenuItem(
                    value: p,
                    child: Text(p.nombre),
                  ))
                      .toList(),
                  onChanged: (p) =>
                      setState(() => _puestoSeleccionado = p),
                ),
              ),
            ),

            // Descripción del puesto
            if (_puestoSeleccionado != null &&
                _puestoSeleccionado!.descripcion.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF005DB9).withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 14, color: Color(0xFF005DB9)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _puestoSeleccionado!.descripcion,
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF005DB9)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Observaciones
            Text('Observaciones',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.grey[600])),
            const SizedBox(height: 8),
            TextField(
              controller: _observacionesCtrl,
              maxLines: 4,
              style: GoogleFonts.poppins(fontSize: 13),
              decoration: InputDecoration(
                hintText:
                'Explica por qué te interesa este puesto...',
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
                    : Text('Enviar solicitud',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15)),
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

class _ItemLeyenda extends StatelessWidget {
  final Color color;
  final String texto;
  const _ItemLeyenda({required this.color, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(texto,
            style: GoogleFonts.poppins(
                fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }
}