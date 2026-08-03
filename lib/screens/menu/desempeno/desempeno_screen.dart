import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/desempeno/desempeno_service.dart';
import '../../../config/usuario_config.dart';

class DesempenoScreen extends StatefulWidget {
  const DesempenoScreen({super.key});

  @override
  State<DesempenoScreen> createState() => _DesempenoScreenState();
}

class _DesempenoScreenState extends State<DesempenoScreen> {
  final _service = DesempenoService();

  List<PeriodoModel> _periodos = [];
  PeriodoModel? _periodoSeleccionado;
  ResultadoEquipoModel? _resultadoEquipo;
  bool _cargandoPeriodos = true;
  bool _cargandoResultados = false;

  @override
  void initState() {
    super.initState();
    _cargarPeriodos();
  }

  Future<void> _cargarPeriodos() async {
    setState(() => _cargandoPeriodos = true);
    final periodos = await _service.obtenerPeriodos();
    setState(() {
      _periodos = periodos;
      _cargandoPeriodos = false;
      if (periodos.isNotEmpty) {
        _periodoSeleccionado = periodos.first;
        _cargarResultados();
      }
    });
  }

  Future<void> _cargarResultados() async {
    if (_periodoSeleccionado == null) return;
    setState(() => _cargandoResultados = true);
    final resultado = await _service.obtenerResultadoEquipo(
      periodoId: _periodoSeleccionado!.id,
      colaboradorId: UsuarioConfig.usuarioId,
    );
    setState(() {
      _resultadoEquipo = resultado;
      _cargandoResultados = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text('Desempeño',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Color(0xFF005DB9)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _cargandoPeriodos
          ? const Center(child: CircularProgressIndicator())
          : _periodos.isEmpty
          ? _buildVacio()
          : RefreshIndicator(
        onRefresh: _cargarResultados,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
                child: _buildSelectorPeriodo()),
            SliverToBoxAdapter(child: _buildMiDesempeno()),
            if ((_resultadoEquipo?.equipo.isNotEmpty ?? false))
              SliverToBoxAdapter(child: _buildEquipo()),
            const SliverToBoxAdapter(
                child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildVacio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insights_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text('Sin periodos disponibles',
              style: GoogleFonts.poppins(
                  color: Colors.grey[400], fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildSelectorPeriodo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
      child: DropdownButtonHideUnderline(
        child: DropdownButton<PeriodoModel>(
          value: _periodoSeleccionado,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF005DB9)),
          style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A2E)),
          items: _periodos
              .map((p) => DropdownMenuItem(
            value: p,
            child: Text(p.nombre),
          ))
              .toList(),
          onChanged: (p) {
            setState(() => _periodoSeleccionado = p);
            _cargarResultados();
          },
        ),
      ),
    );
  }

  Widget _buildMiDesempeno() {
    if (_cargandoResultados) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final yo = _resultadoEquipo?.yo;
    final score = yo?.totalFinal ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text('Mi desempeño',
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2E))),
        ),
        GestureDetector(
          onTap: () => _abrirDetalle(
            colaboradorId: UsuarioConfig.usuarioId,
            nombre: yo?.nombre ?? UsuarioConfig.nombreUsuario,
            fotografia: yo?.fotografia ?? UsuarioConfig.avatarUsuario,
          ),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _gradienteScore(score),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _colorScore(score).withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border:
                    Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundImage: (yo?.fotografia ?? '').isNotEmpty
                        ? NetworkImage(yo!.fotografia)
                        : null,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: (yo?.fotografia ?? '').isEmpty
                        ? Text(
                      (yo?.nombre ?? 'M').isNotEmpty
                          ? (yo?.nombre ?? 'M')[0].toUpperCase()
                          : 'M',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700),
                    )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        yo?.nombre ?? UsuarioConfig.nombreUsuario,
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700),
                      ),
                      Text('Ver detalle de KPIs',
                          style: GoogleFonts.poppins(
                              color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                // Score circular
                _CircularScore(score: score),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEquipo() {
    final equipo = _resultadoEquipo!.equipo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text('Mi equipo',
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2E))),
        ),
        ...equipo.map((miembro) => GestureDetector(
          onTap: () => _abrirDetalle(
            colaboradorId: miembro.empleadoId,
            nombre: miembro.nombre,
            fotografia: miembro.fotografia,
          ),
          child: Container(
            margin:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
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
                CircleAvatar(
                  radius: 22,
                  backgroundImage: miembro.fotografia.isNotEmpty
                      ? NetworkImage(miembro.fotografia)
                      : null,
                  backgroundColor: const Color(0xFF005DB9).withOpacity(0.1),
                  child: miembro.fotografia.isEmpty
                      ? Text(
                    miembro.nombre.isNotEmpty
                        ? miembro.nombre[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.poppins(
                        color: const Color(0xFF005DB9),
                        fontWeight: FontWeight.w700),
                  )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(miembro.nombreCompleto,
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: const Color(0xFF1A1A2E))),
                      Text('Ver detalle',
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[400])),
                    ],
                  ),
                ),
                // Mini score
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _colorScore(miembro.totalFinal).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${miembro.totalFinal.toStringAsFixed(0)}%',
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _colorScore(miembro.totalFinal)),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded,
                    color: Colors.grey[300]),
              ],
            ),
          ),
        )),
      ],
    );
  }

  void _abrirDetalle({
    required String colaboradorId,
    required String nombre,
    required String fotografia,
  }) {
    if (_periodoSeleccionado == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _DetalleDesempenoScreen(
          periodoId: _periodoSeleccionado!.id,
          periodoNombre: _periodoSeleccionado!.nombre,
          colaboradorId: colaboradorId,
          nombre: nombre,
          fotografia: fotografia,
        ),
      ),
    );
  }

  Color _colorScore(double score) {
    if (score >= 85) return const Color(0xFF00B37E);
    if (score >= 60) return const Color(0xFFFF6B35);
    return const Color(0xFFF32836);
  }

  List<Color> _gradienteScore(double score) {
    if (score >= 85) {
      return [const Color(0xFF00B37E), const Color(0xFF00D68F)];
    }
    if (score >= 60) {
      return [const Color(0xFFFF6B35), const Color(0xFFFFAA00)];
    }
    return [const Color(0xFFF32836), const Color(0xFFFF6B6B)];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DETALLE KPIs
// ─────────────────────────────────────────────────────────────────────────────

class _DetalleDesempenoScreen extends StatefulWidget {
  final String periodoId;
  final String periodoNombre;
  final String colaboradorId;
  final String nombre;
  final String fotografia;

  const _DetalleDesempenoScreen({
    required this.periodoId,
    required this.periodoNombre,
    required this.colaboradorId,
    required this.nombre,
    required this.fotografia,
  });

  @override
  State<_DetalleDesempenoScreen> createState() =>
      _DetalleDesempenoScreenState();
}

class _DetalleDesempenoScreenState extends State<_DetalleDesempenoScreen> {
  final _service = DesempenoService();
  DetalleColaboradorModel? _detalle;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final detalle = await _service.obtenerDetalleColaborador(
      periodoId: widget.periodoId,
      colaboradorId: widget.colaboradorId,
    );
    setState(() {
      _detalle = detalle;
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text(widget.periodoNombre,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Color(0xFF005DB9)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _detalle == null
          ? _buildSinDatos()
          : _buildContenido(),
    );
  }

  Widget _buildSinDatos() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text('Sin datos para este periodo',
              style: GoogleFonts.poppins(
                  color: Colors.grey[400], fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildContenido() {
    final d = _detalle!;
    final score = d.totalFinal;

    return CustomScrollView(
      slivers: [
        // ── Header con score ─────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: _gradienteScore(score),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _colorScore(score).withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: widget.fotografia.isNotEmpty
                      ? NetworkImage(widget.fotografia)
                      : null,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: widget.fotografia.isEmpty
                      ? Text(widget.nombre.isNotEmpty
                      ? widget.nombre[0].toUpperCase()
                      : '?',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700))
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.nombreCompleto,
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _PillDetalle(
                              texto:
                              '${d.cumplidos}/${d.kpis.length} KPIs cumplidos'),
                        ],
                      ),
                    ],
                  ),
                ),
                _CircularScore(score: score),
              ],
            ),
          ),
        ),

        // ── Lista de KPIs ─────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, i) => _TarjetaKpi(kpi: d.kpis[i]),
              childCount: d.kpis.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  Color _colorScore(double score) {
    if (score >= 85) return const Color(0xFF00B37E);
    if (score >= 60) return const Color(0xFFFF6B35);
    return const Color(0xFFF32836);
  }

  LinearGradient _gradienteScore(double score) {
    if (score >= 85) {
      return const LinearGradient(
          colors: [Color(0xFF00B37E), Color(0xFF00D68F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight);
    }
    if (score >= 60) {
      return const LinearGradient(
          colors: [Color(0xFFFF6B35), Color(0xFFFFAA00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight);
    }
    return const LinearGradient(
        colors: [Color(0xFFF32836), Color(0xFFFF6B6B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TARJETA KPI
// ─────────────────────────────────────────────────────────────────────────────

class _TarjetaKpi extends StatelessWidget {
  final KpiModel kpi;
  const _TarjetaKpi({required this.kpi});

  @override
  Widget build(BuildContext context) {
    final color =
    kpi.cumplimiento ? const Color(0xFF00B37E) : const Color(0xFFF32836);
    final progreso =
    kpi.meta > 0 ? (kpi.resultado / kpi.meta).clamp(0.0, 1.0) : 0.0;

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header KPI
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  kpi.cumplimiento
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  kpi.nombre,
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: const Color(0xFF1A1A2E)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  kpi.cumplimiento ? 'Cumplido' : 'No cumplido',
                  style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Descripción
          Text(
            kpi.descripcion,
            style: GoogleFonts.poppins(
                fontSize: 11, color: Colors.grey[500], height: 1.4),
          ),
          const SizedBox(height: 12),

          // Barra de progreso
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progreso,
              minHeight: 6,
              backgroundColor: Colors.grey[100],
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 8),

          // Meta vs Resultado + Ponderación
          Row(
            children: [
              _MiniStat(
                  etiqueta: 'Meta',
                  valor: _formatearValor(kpi.meta)),
              const SizedBox(width: 16),
              _MiniStat(
                  etiqueta: 'Resultado',
                  valor: _formatearValor(kpi.resultado)),
              const Spacer(),
              Text(
                'Peso: ${(kpi.ponderacion * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatearValor(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }
}

class _MiniStat extends StatelessWidget {
  final String etiqueta;
  final String valor;
  const _MiniStat({required this.etiqueta, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta,
            style: GoogleFonts.poppins(
                fontSize: 10, color: Colors.grey[400])),
        Text(valor,
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A2E))),
      ],
    );
  }
}

class _PillDetalle extends StatelessWidget {
  final String texto;
  const _PillDetalle({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(texto,
          style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCORE CIRCULAR
// ─────────────────────────────────────────────────────────────────────────────

class _CircularScore extends StatelessWidget {
  final double score;
  const _CircularScore({required this.score});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: (score / 100).clamp(0.0, 1.0),
            strokeWidth: 5,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation(Colors.white),
            strokeCap: StrokeCap.round,
          ),
          Center(
            child: Text(
              '${score.toStringAsFixed(0)}%',
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}