import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/publicacion_model.dart';
import '../services/publicaciones/publicaciones_service.dart';
import '../config/usuario_config.dart';

class PublicacionCard extends StatefulWidget {
  final PublicacionModel publicacion;
  final VoidCallback? onReportar;

  const PublicacionCard({
    super.key,
    required this.publicacion,
    this.onReportar,
  });

  @override
  State<PublicacionCard> createState() => _PublicacionCardState();
}

class _PublicacionCardState extends State<PublicacionCard>
    with SingleTickerProviderStateMixin {
  final PublicacionesService _service = PublicacionesService();

  late AnimationController _likeController;
  late Animation<double> _likeScale;

  bool _likeado = false;
  bool _mostrarComentarios = false;
  bool _enviandoComentario = false;
  String? _miReaccion;

  final _comentarioCtrl = TextEditingController();
  final _focusComentario = FocusNode();

  static const _emojisReaccion = {
    'me_gusta': '👍',
    'me_encanta': '❤️',
    'me_divierte': '😂',
    'me_asombra': '😮',
    'me_entristece': '😢',
    'me_enoja': '😡',
  };

  static const _etiquetasCategoria = {
    'anuncios': '📢 Anuncios',
    'capacitacion': '📚 Capacitación',
    'cultura': '🎉 Cultura',
    'reconocimiento': '🏆 Reconocimiento',
  };

  @override
  void initState() {
    super.initState();
    _likeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _likeScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.5), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.5, end: 1.0), weight: 50),
    ]).animate(
        CurvedAnimation(parent: _likeController, curve: Curves.easeOut));
    _cargarEstado();
  }

  @override
  void dispose() {
    _likeController.dispose();
    _comentarioCtrl.dispose();
    _focusComentario.dispose();
    super.dispose();
  }

  Future<void> _cargarEstado() async {
    if (widget.publicacion.id == null) return;
    final likeado = await _service.estaLikeado(widget.publicacion.id!);
    final reaccion = await _service.miReaccion(widget.publicacion.id!);
    if (mounted) setState(() {
      _likeado = likeado;
      _miReaccion = reaccion;
    });
  }

  Future<void> _toggleLike() async {
    if (widget.publicacion.id == null) return;
    HapticFeedback.lightImpact();
    setState(() => _likeado = !_likeado);
    _likeController.forward(from: 0);
    await _service.toggleLike(widget.publicacion.id!);
  }

  void _mostrarReacciones() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PanelReacciones(
        reaccionActual: _miReaccion,
        onReaccionar: (tipo) async {
          Navigator.pop(context);
          setState(() => _miReaccion = tipo);
          await _service.reaccionar(widget.publicacion.id!, tipo);
          setState(() {});
        },
      ),
    );
  }

  String _formatearFecha(dynamic ts) {
    try {
      final fecha = ts.toDate() as DateTime;
      final diff = DateTime.now().difference(fecha);
      if (diff.inMinutes < 1) return 'ahora';
      if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'hace ${diff.inHours} h';
      if (diff.inDays < 7) return 'hace ${diff.inDays} d';
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    } catch (_) {
      return '';
    }
  }

  int get _totalLikes =>
      widget.publicacion.likes + (_likeado ? 0 : 0); // viene de Firestore

  @override
  Widget build(BuildContext context) {
    final pub = widget.publicacion;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Imagen (si hay) ──────────────────────────────────────────────
          if (pub.urlImagen != null) _buildImagen(pub.urlImagen!),

          // ── Contenido ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado usuario
                _buildEncabezado(pub),
                const SizedBox(height: 10),

                // Texto
                Text(
                  pub.contenido,
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      height: 1.5,
                      color: const Color(0xFF2D2D2D)),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),

                // Stats chips + fecha
                _buildStats(pub),
              ],
            ),
          ),

          // ── Sección comentarios (expandible) ─────────────────────────────
          if (_mostrarComentarios) _buildComentarios(pub),
        ],
      ),
    );
  }

  Widget _buildImagen(String url) {
    return GestureDetector(
      onDoubleTap: () {
        if (!_likeado) _toggleLike();
      },
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Container(
          color: Colors.white,
          constraints: const BoxConstraints(
            maxHeight: 340,
          ),
          width: double.infinity,
          child: Image.network(
            url,
            fit: BoxFit.contain,
            frameBuilder: (_, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded) return child;
              return AnimatedOpacity(
                opacity: frame == null ? 0 : 1,
                duration: const Duration(milliseconds: 300),
                child: child,
              );
            },
            errorBuilder: (_, __, ___) => Container(
              height: 160,
              color: Colors.grey[100],
              child: Center(
                child: Icon(Icons.broken_image_outlined,
                    color: Colors.grey[300], size: 40),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEncabezado(PublicacionModel pub) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundImage: pub.avatarUsuario.isNotEmpty
              ? NetworkImage(pub.avatarUsuario)
              : null,
          backgroundColor: const Color(0xFF005DB9),
          child: pub.avatarUsuario.isEmpty
              ? Text(
            pub.nombreUsuario.isNotEmpty
                ? pub.nombreUsuario[0].toUpperCase()
                : '?',
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14),
          )
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pub.nombreUsuario,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: const Color(0xFF1A1A2E)),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _formatearFecha(pub.creadoEn),
                style: GoogleFonts.poppins(
                    fontSize: 11, color: Colors.grey[400]),
              ),
            ],
          ),
        ),
        // Categoría pill
        Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF005DB9).withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _etiquetasCategoria[pub.categoria] ?? pub.categoria,
            style: GoogleFonts.poppins(
                fontSize: 10,
                color: const Color(0xFF005DB9),
                fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: widget.onReportar,
          child: Icon(Icons.more_horiz_rounded,
              color: Colors.grey[400], size: 20),
        ),
      ],
    );
  }

  Widget _buildStats(PublicacionModel pub) {
    return Row(
      children: [
        // Like
        GestureDetector(
          onTap: _toggleLike,
          onLongPress: _mostrarReacciones,
          child: _StatChip(
            icono: _miReaccion != null
                ? null
                : (_likeado
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded),
            emoji: _miReaccion != null
                ? _emojisReaccion[_miReaccion!]
                : null,
            valor: '${pub.likes}',
            color: const Color(0xFFF32836),
            activo: _likeado || _miReaccion != null,
            escala: _likeScale,
          ),
        ),
        const SizedBox(width: 10),
        // Comentarios
        GestureDetector(
          onTap: () {
            setState(
                    () => _mostrarComentarios = !_mostrarComentarios);
            if (_mostrarComentarios) {
              Future.delayed(const Duration(milliseconds: 300),
                      () => _focusComentario.requestFocus());
            }
          },
          child: _StatChip(
            icono: Icons.chat_bubble_outline_rounded,
            valor: '${pub.comentarios}',
            color: const Color(0xFF009BDF),
            activo: _mostrarComentarios,
          ),
        ),
        const Spacer(),
        Text(
          _formatearFecha(pub.creadoEn),
          style: GoogleFonts.poppins(
              fontSize: 11, color: Colors.grey[400]),
        ),
      ],
    );
  }

  Widget _buildComentarios(PublicacionModel pub) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFC),
        borderRadius:
        const BorderRadius.vertical(bottom: Radius.circular(20)),
        border: Border(top: BorderSide(color: Colors.grey[100]!)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lista comentarios
          StreamBuilder<List<ComentarioModel>>(
            stream: _service.obtenerComentarios(pub.id!),
            builder: (context, snap) {
              final comentarios = snap.data ?? [];
              if (comentarios.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Sé el primero en comentar 👋',
                    style: GoogleFonts.poppins(
                        color: Colors.grey[400], fontSize: 13),
                  ),
                );
              }
              return Column(
                children: [
                  ...comentarios
                      .take(3)
                      .map((c) => _ItemComentario(c)),
                  if (comentarios.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Ver ${comentarios.length - 3} comentarios más',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF005DB9),
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),

          // Campo comentario
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF005DB9), Color(0xFF009BDF)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    UsuarioConfig.nombreUsuario.isNotEmpty
                        ? UsuarioConfig.nombreUsuario[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _comentarioCtrl,
                  focusNode: _focusComentario,
                  style: GoogleFonts.poppins(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Escribe un comentario...',
                    hintStyle: GoogleFonts.poppins(
                        fontSize: 13, color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide:
                      BorderSide(color: Colors.grey[200]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide:
                      BorderSide(color: Colors.grey[200]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(
                          color: Color(0xFF005DB9), width: 1.5),
                    ),
                    suffixIcon: _enviandoComentario
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
                      icon: const Icon(Icons.send_rounded,
                          color: Color(0xFF005DB9), size: 18),
                      onPressed: _enviarComentario,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  onSubmitted: (_) => _enviarComentario(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _enviarComentario() async {
    final texto = _comentarioCtrl.text.trim();
    if (texto.isEmpty || widget.publicacion.id == null) return;
    HapticFeedback.lightImpact();
    setState(() => _enviandoComentario = true);
    await _service.agregarComentario(widget.publicacion.id!, texto);
    _comentarioCtrl.clear();
    if (mounted) setState(() => _enviandoComentario = false);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STAT CHIP (igual al del mockup de perfil)
// ─────────────────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData? icono;
  final String? emoji;
  final String valor;
  final Color color;
  final bool activo;
  final Animation<double>? escala;

  const _StatChip({
    this.icono,
    this.emoji,
    required this.valor,
    required this.color,
    this.activo = false,
    this.escala,
  });

  @override
  Widget build(BuildContext context) {
    Widget iconWidget;

    if (emoji != null) {
      iconWidget = Text(emoji!, style: const TextStyle(fontSize: 14));
    } else {
      final icon = Icon(icono!, size: 14, color: color);
      iconWidget = escala != null
          ? ScaleTransition(scale: escala!, child: icon)
          : icon;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(activo ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconWidget,
          const SizedBox(width: 5),
          Text(
            valor,
            style: GoogleFonts.poppins(
                fontSize: 12,
                color: color,
                fontWeight:
                activo ? FontWeight.w700 : FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ITEM COMENTARIO
// ─────────────────────────────────────────────────────────────────────────────

class _ItemComentario extends StatelessWidget {
  final ComentarioModel comentario;
  const _ItemComentario(this.comentario);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
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
                  color: Colors.white, fontSize: 10),
            )
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey[100]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comentario.nombreUsuario,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: const Color(0xFF1A1A2E)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    comentario.texto,
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: const Color(0xFF2D2D2D)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PANEL DE REACCIONES
// ─────────────────────────────────────────────────────────────────────────────

class _PanelReacciones extends StatelessWidget {
  final Function(String tipo) onReaccionar;
  final String? reaccionActual;

  const _PanelReacciones({
    required this.onReaccionar,
    this.reaccionActual,
  });

  static const _reacciones = [
    ('me_gusta', '👍', 'Gusta'),
    ('me_encanta', '❤️', 'Encanta'),
    ('me_divierte', '😂', 'Divierte'),
    ('me_asombra', '😮', 'Asombra'),
    ('me_entristece', '😢', 'Tristeza'),
    ('me_enoja', '😡', 'Enoja'),
  ];

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        padding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _reacciones.map((r) {
            final activa = reaccionActual == r.$1;
            return GestureDetector(
              onTap: () => onReaccionar(r.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  color: activa
                      ? const Color(0xFF005DB9).withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      r.$2,
                      style: TextStyle(
                          fontSize: activa ? 28 : 24),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      r.$3,
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        color: activa
                            ? const Color(0xFF005DB9)
                            : Colors.grey[500],
                        fontWeight: activa
                            ? FontWeight.w700
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}