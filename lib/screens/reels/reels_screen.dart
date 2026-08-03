import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../../models/reel_model.dart';
import '../../services/reels/reels_service.dart';
import '../../services/reportes/reportes_service.dart';
import '../../config/usuario_config.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  ReelsScreenState createState() => ReelsScreenState();
}

class ReelsScreenState extends State<ReelsScreen> with WidgetsBindingObserver {
  void pausarActual() {
    _controladores[_paginaActual]?.pause();
  }

  void reanudarActual() {
    _controladores[_paginaActual]?.play();
  }

  final ReelsService _service = ReelsService();
  final PageController _pageController = PageController();
  List<ReelModel> _reels = [];
  int _paginaActual = 0;

  // Pool de controladores: solo mantenemos 3 activos (anterior, actual, siguiente)
  final Map<int, VideoPlayerController> _controladores = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cargarReels();
  }

  Future<void> _cargarReels() async {
    _service.obtenerAprobados().listen((reels) {
      if (!mounted) return;
      setState(() => _reels = reels);
      if (reels.isNotEmpty) {
        _iniciarControlador(0);
        if (reels.length > 1) _iniciarControlador(1);
      }
    });
  }

  Future<void> _iniciarControlador(int indice) async {
    if (indice < 0 || indice >= _reels.length) return;
    if (_controladores.containsKey(indice)) return;

    final reel = _reels[indice];
    if (reel.urlVideo.isEmpty) return;

    final ctrl = VideoPlayerController.networkUrl(Uri.parse(reel.urlVideo));
    _controladores[indice] = ctrl;

    await ctrl.initialize();
    ctrl.setLooping(true);

    // Solo reproducir si es el actual
    if (indice == _paginaActual && mounted) {
      ctrl.play();
      setState(() {});
    } else if (mounted) {
      setState(() {});
    }
  }

  void _liberarControlador(int indice) {
    final ctrl = _controladores.remove(indice);
    ctrl?.dispose();
  }

  void _onCambioPagina(int nuevaPagina) {
    final anterior = _paginaActual;
    _paginaActual = nuevaPagina;

    // Pausar anterior
    _controladores[anterior]?.pause();

    // Reproducir actual
    final ctrlActual = _controladores[nuevaPagina];
    if (ctrlActual != null && ctrlActual.value.isInitialized) {
      ctrlActual.seekTo(Duration.zero);
      ctrlActual.play();
    }

    // Precargar siguiente
    _iniciarControlador(nuevaPagina + 1);

    // Liberar controladores lejanos (más de 2 posiciones)
    final aLiberar = _controladores.keys
        .where((i) => (i - nuevaPagina).abs() > 2)
        .toList();
    for (final i in aLiberar) {
      _liberarControlador(i);
    }

    // Contar vista
    if (_reels[nuevaPagina].id != null) {
      _service.incrementarVistas(_reels[nuevaPagina].id!);
    }

    setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final ctrl in _controladores.values) {
      ctrl.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _controladores[_paginaActual]?.pause();
    } else {
      _controladores[_paginaActual]?.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _reels.isEmpty
            ? _buildVacio()
            : PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          itemCount: _reels.length,
          onPageChanged: _onCambioPagina,
          itemBuilder: (context, i) => _ReelItem(
            reel: _reels[i],
            controlador: _controladores[i],
            estaActivo: i == _paginaActual,
            onTogglePausa: () {
              final ctrl = _controladores[i];
              if (ctrl == null) return;
              if (ctrl.value.isPlaying) {
                ctrl.pause();
              } else {
                ctrl.play();
              }
              setState(() {});
            },
          ),
        ),
      ),
    );
  }

  Widget _buildVacio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.play_circle_outline, color: Colors.white24, size: 72),
          const SizedBox(height: 16),
          Text('Sin reels disponibles',
              style: GoogleFonts.poppins(color: Colors.white38, fontSize: 16)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ITEM DEL REEL
// ─────────────────────────────────────────────────────────────────────────────

class _ReelItem extends StatefulWidget {
  final ReelModel reel;
  final VideoPlayerController? controlador;
  final bool estaActivo;
  final VoidCallback onTogglePausa;

  const _ReelItem({
    required this.reel,
    required this.controlador,
    required this.estaActivo,
    required this.onTogglePausa,
  });

  @override
  State<_ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<_ReelItem>
    with SingleTickerProviderStateMixin {
  final ReelsService _service = ReelsService();
  final ReportesService _reportesService = ReportesService();

  bool _likeado = false;
  bool _silenciado = false;
  bool _mostrandoComentarios = false;
  bool _mostrandoPausa = false;

  late AnimationController _pausaController;

  @override
  void initState() {
    super.initState();
    _pausaController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _cargarLike();
  }

  @override
  void dispose() {
    _pausaController.dispose();
    super.dispose();
  }

  Future<void> _cargarLike() async {
    if (widget.reel.id == null) return;
    final likeado = await _service.estaLikeado(widget.reel.id!);
    if (mounted) setState(() => _likeado = likeado);
  }

  Future<void> _toggleLike() async {
    if (widget.reel.id == null) return;
    setState(() => _likeado = !_likeado);
    await _service.toggleLike(widget.reel.id!);
  }

  void _toggleSilencio() {
    setState(() => _silenciado = !_silenciado);
    widget.controlador?.setVolume(_silenciado ? 0 : 1);
  }

  void _onTap() {
    widget.onTogglePausa();
    final pausado = !(widget.controlador?.value.isPlaying ?? false);
    if (pausado) {
      setState(() => _mostrandoPausa = true);
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) setState(() => _mostrandoPausa = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controlador;
    final iniciado = ctrl != null && ctrl.value.isInitialized;
    final pausado = ctrl != null && !ctrl.value.isPlaying;

    return GestureDetector(
      onTap: _onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Video / Fondo ────────────────────────────────────────────────
          if (iniciado)
            _VideoFit(controlador: ctrl)
          else
            _buildMiniatura(),

          // ── Gradiente ────────────────────────────────────────────────────
          _buildGradiente(),

          // ── Indicador pausa ──────────────────────────────────────────────
          if (_mostrandoPausa || (pausado && widget.estaActivo && iniciado))
            Center(
              child: AnimatedOpacity(
                opacity: _mostrandoPausa ? 1 : 0.6,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.pause_rounded,
                      color: Colors.white, size: 40),
                ),
              ),
            ),

          // ── Header ──────────────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildHeader(),
          ),

          // ── Info izquierda abajo ─────────────────────────────────────────
          Positioned(
            left: 16,
            right: 72,
            bottom: iniciado ? 56 : 80,
            child: _buildInfo(),
          ),

          // ── Acciones derecha ─────────────────────────────────────────────
          Positioned(
            right: 12,
            bottom: iniciado ? 72 : 96,
            child: _buildAcciones(),
          ),

          // ── Barra de progreso ────────────────────────────────────────────
          if (iniciado)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _BarraProgreso(controlador: ctrl),
            ),

          // ── Panel comentarios ────────────────────────────────────────────
          if (_mostrandoComentarios)
            Positioned.fill(
              child: _PanelComentarios(
                reelId: widget.reel.id!,
                service: _service,
                onCerrar: () =>
                    setState(() => _mostrandoComentarios = false),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMiniatura() {
    if (widget.reel.urlMiniatura.isNotEmpty) {
      return Image.network(widget.reel.urlMiniatura,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Container(color: Colors.grey[900]));
    }
    return Container(
      color: Colors.grey[900],
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white24),
      ),
    );
  }

  Widget _buildGradiente() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.3, 0.7, 1.0],
          colors: [
            Colors.black54,
            Colors.transparent,
            Colors.transparent,
            Colors.black87,
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Text('Reels',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
            const Spacer(),
            GestureDetector(
              onTap: _toggleSilencio,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _silenciado
                      ? Icons.volume_off_rounded
                      : Icons.volume_up_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo() {
    final reel = widget.reel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Usuario
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: reel.avatarUsuario.isNotEmpty
                  ? NetworkImage(reel.avatarUsuario)
                  : null,
              backgroundColor: const Color(0xFF005DB9),
              child: reel.avatarUsuario.isEmpty
                  ? Text(
                  reel.nombreUsuario.isNotEmpty
                      ? reel.nombreUsuario[0].toUpperCase()
                      : '?',
                  style: const TextStyle(color: Colors.white))
                  : null,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(reel.nombreUsuario,
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Título
        Text(reel.titulo,
            style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15)),
        // Descripción
        if (reel.descripcion.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(reel.descripcion,
              style: GoogleFonts.poppins(
                  color: Colors.white70, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
        const SizedBox(height: 8),
        // Categoría
        Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24),
          ),
          child: Text(_etiquetaCategoria(reel.categoria),
              style: GoogleFonts.poppins(
                  color: Colors.white, fontSize: 11)),
        ),
      ],
    );
  }

  Widget _buildAcciones() {
    final reel = widget.reel;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Like
        _BotonAccion(
          icono: _likeado
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          color: _likeado ? const Color(0xFFF32836) : Colors.white,
          etiqueta: '${reel.likes}',
          onTap: _toggleLike,
        ),
        const SizedBox(height: 24),
        // Comentar
        _BotonAccion(
          icono: Icons.chat_bubble_outline_rounded,
          color: Colors.white,
          etiqueta: '${reel.comentarios}',
          onTap: () => setState(() => _mostrandoComentarios = true),
        ),
        const SizedBox(height: 24),
        // Más opciones
        _BotonAccion(
          icono: Icons.more_vert_rounded,
          color: Colors.white,
          onTap: _mostrarOpciones,
        ),
      ],
    );
  }

  void _mostrarOpciones() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 4),
            ListTile(
              leading: const Icon(Icons.flag_outlined,
                  color: Color(0xFFF32836)),
              title: Text('Reportar reel',
                  style: GoogleFonts.poppins(fontSize: 14)),
              onTap: () {
                Navigator.pop(context);
                _mostrarReporte();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _mostrarReporte() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ModalReporte(
        onReportar: (motivo) async {
          if (widget.reel.id == null) return;
          await _reportesService.reportar(
            tipo: 'reel',
            contenidoId: widget.reel.id!,
            motivo: motivo,
          );
        },
      ),
    );
  }

  String _etiquetaCategoria(String cat) {
    const mapa = {
      'cultura': '🎉 Cultura',
      'anuncios': '📢 Anuncios',
      'capacitacion': '📚 Capacitación',
      'reconocimiento': '🏆 Reconocimiento',
    };
    return mapa[cat] ?? cat;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VIDEO FIT (mantiene relación de aspecto correcta)
// ─────────────────────────────────────────────────────────────────────────────

class _VideoFit extends StatelessWidget {
  final VideoPlayerController controlador;
  const _VideoFit({required this.controlador});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controlador.value.size.width,
          height: controlador.value.size.height,
          child: VideoPlayer(controlador),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BARRA DE PROGRESO
// ─────────────────────────────────────────────────────────────────────────────

class _BarraProgreso extends StatefulWidget {
  final VideoPlayerController controlador;
  const _BarraProgreso({required this.controlador});

  @override
  State<_BarraProgreso> createState() => _BarraProgresoState();
}

class _BarraProgresoState extends State<_BarraProgreso> {
  @override
  void initState() {
    super.initState();
    widget.controlador.addListener(_actualizar);
  }

  void _actualizar() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controlador.removeListener(_actualizar);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final duracion = widget.controlador.value.duration.inMilliseconds;
    final posicion = widget.controlador.value.position.inMilliseconds;
    final progreso = duracion > 0 ? posicion / duracion : 0.0;

    return Container(
      height: 3,
      child: LinearProgressIndicator(
        value: progreso.clamp(0.0, 1.0),
        backgroundColor: Colors.white24,
        valueColor:
        const AlwaysStoppedAnimation<Color>(Color(0xFF009BDF)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTÓN DE ACCIÓN
// ─────────────────────────────────────────────────────────────────────────────

class _BotonAccion extends StatelessWidget {
  final IconData icono;
  final Color color;
  final String? etiqueta;
  final VoidCallback onTap;

  const _BotonAccion({
    required this.icono,
    required this.color,
    this.etiqueta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icono, color: color, size: 30),
          if (etiqueta != null) ...[
            const SizedBox(height: 4),
            Text(etiqueta!,
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      const Shadow(color: Colors.black54, blurRadius: 4)
                    ])),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PANEL DE COMENTARIOS
// ─────────────────────────────────────────────────────────────────────────────

class _PanelComentarios extends StatefulWidget {
  final String reelId;
  final ReelsService service;
  final VoidCallback onCerrar;

  const _PanelComentarios({
    required this.reelId,
    required this.service,
    required this.onCerrar,
  });

  @override
  State<_PanelComentarios> createState() => _PanelComentariosState();
}

class _PanelComentariosState extends State<_PanelComentarios> {
  final TextEditingController _ctrl = TextEditingController();
  bool _enviando = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onCerrar,
      child: Container(
        color: Colors.black54,
        child: GestureDetector(
          onTap: () {}, // evitar que el tap se propague
          child: DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            builder: (_, scrollController) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Text('Comentarios',
                            style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                        const Spacer(),
                        GestureDetector(
                          onTap: widget.onCerrar,
                          child: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: StreamBuilder<List<ComentarioReelModel>>(
                      stream: widget.service
                          .obtenerComentarios(widget.reelId),
                      builder: (context, snap) {
                        final comentarios = snap.data ?? [];
                        if (comentarios.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.chat_bubble_outline,
                                    size: 48,
                                    color: Colors.grey[300]),
                                const SizedBox(height: 8),
                                Text('Sé el primero en comentar',
                                    style: GoogleFonts.poppins(
                                        color: Colors.grey[400])),
                              ],
                            ),
                          );
                        }
                        return ListView.builder(
                          controller: scrollController,
                          padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: comentarios.length,
                          itemBuilder: (_, i) =>
                              _ItemComentario(comentarios[i]),
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: EdgeInsets.only(
                      left: 12,
                      right: 12,
                      top: 8,
                      bottom:
                      MediaQuery.of(context).viewInsets.bottom + 12,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFF005DB9),
                          child: Text(
                            UsuarioConfig.nombreUsuario.isNotEmpty
                                ? UsuarioConfig.nombreUsuario[0]
                                .toUpperCase()
                                : '?',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _ctrl,
                            decoration: InputDecoration(
                              hintText: 'Escribe un comentario...',
                              hintStyle: GoogleFonts.poppins(
                                  fontSize: 13, color: Colors.grey),
                              filled: true,
                              fillColor: Colors.grey[100],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(22),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding:
                              const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              isDense: true,
                              suffixIcon: _enviando
                                  ? const Padding(
                                padding: EdgeInsets.all(10),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                ),
                              )
                                  : IconButton(
                                icon: const Icon(
                                    Icons.send_rounded,
                                    color: Color(0xFF005DB9),
                                    size: 20),
                                onPressed: _enviar,
                                padding: EdgeInsets.zero,
                              ),
                            ),
                            onSubmitted: (_) => _enviar(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _enviar() async {
    final texto = _ctrl.text.trim();
    if (texto.isEmpty) return;
    setState(() => _enviando = true);
    await widget.service.agregarComentario(widget.reelId, texto);
    _ctrl.clear();
    if (mounted) setState(() => _enviando = false);
  }
}

class _ItemComentario extends StatelessWidget {
  final ComentarioReelModel comentario;
  const _ItemComentario(this.comentario);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: comentario.avatarUsuario.isNotEmpty
                ? NetworkImage(comentario.avatarUsuario)
                : null,
            backgroundColor: const Color(0xFF009BDF),
            child: comentario.avatarUsuario.isEmpty
                ? Text(
                comentario.nombreUsuario.isNotEmpty
                    ? comentario.nombreUsuario[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    color: Colors.white, fontSize: 12))
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(comentario.nombreUsuario,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 2),
                Text(comentario.texto,
                    style: GoogleFonts.poppins(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MODAL REPORTE
// ─────────────────────────────────────────────────────────────────────────────

class _ModalReporte extends StatefulWidget {
  final Future<void> Function(String motivo) onReportar;
  const _ModalReporte({required this.onReportar});

  @override
  State<_ModalReporte> createState() => _ModalReporteState();
}

class _ModalReporteState extends State<_ModalReporte> {
  String _motivo = 'Contenido inapropiado';
  bool _enviando = false;

  final _motivos = [
    'Contenido inapropiado',
    'Spam',
    'Información falsa',
    'Acoso o bullying',
    'Otro',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Reportar reel',
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ..._motivos.map((m) => RadioListTile<String>(
              value: m,
              groupValue: _motivo,
              onChanged: (v) => setState(() => _motivo = v!),
              title:
              Text(m, style: GoogleFonts.poppins(fontSize: 14)),
              activeColor: const Color(0xFF005DB9),
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            )),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _enviando
                    ? null
                    : () async {
                  setState(() => _enviando = true);
                  await widget.onReportar(_motivo);
                  if (mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF32836),
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
                    : Text('Enviar reporte',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}