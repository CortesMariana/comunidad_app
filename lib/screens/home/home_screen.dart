import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/publicacion_model.dart';
import '../../models/historia_model.dart';
import '../../models/banner_model.dart';
import '../../services/publicaciones/publicaciones_service.dart';
import '../../services/historias/historias_service.dart';
import '../../services/banners/banners_service.dart';
import '../../services/reportes/reportes_service.dart';
import '../../config/usuario_config.dart';
import '../crear_contenido/crear_banner_screen.dart';
import '../crear_contenido/crear_historia_screen.dart';
import '../crear_contenido/crear_publicacion_screen.dart';
import '../crear_contenido/crear_reel_screen.dart';
import '../reels/reels_screen.dart';
import '../notificaciones/notificaciones_screen.dart';
import '../menu/menu_screen.dart';
import '../perfil/perfil_screen.dart';
import '../../widgets/publicacion_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _indice = 0;

  final _reelsKey = GlobalKey<ReelsScreenState>();
  late final List<Widget> _pantallas;

  @override
  void initState() {
    super.initState();
    _pantallas = [
      const HomeFeedScreen(),
      ReelsScreen(key: _reelsKey),
      const NotificacionesScreen(),
      const MenuScreen(),
      const PerfilScreen(),
    ];
  }

  void _cambiarIndice(int nuevoIndice) {
    if (_indice == 1 && nuevoIndice != 1) {
      _reelsKey.currentState?.pausarActual();
    }
    if (nuevoIndice == 1) {
      _reelsKey.currentState?.reanudarActual();
    }
    setState(() => _indice = nuevoIndice);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: IndexedStack(index: _indice, children: _pantallas),
        bottomNavigationBar: _BarraNavegacion(
          indice: _indice,
          onTap: _cambiarIndice,
        ),
      ),
    );
  }
}

class _BarraNavegacion extends StatelessWidget {
  final int indice;
  final ValueChanged<int> onTap;

  const _BarraNavegacion({required this.indice, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const items = [
      {'icon': Icons.home_outlined, 'active': Icons.home_rounded, 'label': 'Inicio'},
      {'icon': Icons.play_circle_outline, 'active': Icons.play_circle_rounded, 'label': 'Reels'},
      {'icon': Icons.add_circle_outline, 'active': Icons.add_circle, 'label': 'Publicar'},
      {'icon': Icons.notifications_outlined, 'active': Icons.notifications_rounded, 'label': 'Avisos'},
      {'icon': Icons.person_outline_rounded, 'active': Icons.person_rounded, 'label': 'Perfil'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(items.length, (i) {
              // El índice 2 es el botón de publicar (acción especial)
              // En la navegación real usamos 0,1,3,4 → mapeamos:
              // tap 0→0, 1→1, 2→abre modal, 3→2, 4→3
              final esPublicar = i == 2;
              final estaActivo = !esPublicar && _navIndex(i) == indice;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (esPublicar) {
                      _mostrarMenuPublicar(context);
                    } else {
                      onTap(_navIndex(i));
                    }
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (esPublicar)
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF005DB9), Color(0xFF009BDF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
                        )
                      else ...[
                        Icon(
                          estaActivo
                              ? items[i]['active'] as IconData
                              : items[i]['icon'] as IconData,
                          color: estaActivo
                              ? const Color(0xFF005DB9)
                              : Colors.grey[400],
                          size: 24,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          items[i]['label'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: estaActivo ? FontWeight.w600 : FontWeight.w400,
                            color: estaActivo ? const Color(0xFF005DB9) : Colors.grey[400],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  int _navIndex(int i) {
    // 0→0, 1→1, 2→(publicar), 3→2, 4→3
    if (i < 2) return i;
    if (i > 2) return i - 1;
    return -1;
  }

  void _mostrarMenuPublicar(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _MenuPublicar(),
    );
  }
}

class _MenuPublicar extends StatelessWidget {
  const _MenuPublicar();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12.5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 15),
          Text('¿Qué quieres publicar?',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          _OpcionPublicar(
            icono: Icons.article_outlined,
            color: const Color(0xFF005DB9),
            titulo: 'Publicación',
            subtitulo: 'Texto, imagen o video',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CrearPublicacionScreen()));
            },
          ),
          const SizedBox(height: 12),
          _OpcionPublicar(
            icono: Icons.play_circle_outline,
            color: const Color(0xFF009BDF),
            titulo: 'Reel',
            subtitulo: 'Video corto',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CrearReelScreen()));
            },
          ),
          const SizedBox(height: 12),
          _OpcionPublicar(
            icono: Icons.auto_stories_outlined,
            color: const Color(0xFFF32836),
            titulo: 'Historia',
            subtitulo: 'Desaparece en 24 horas',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CrearHistoriaScreen()));
            },
          ),
          const SizedBox(height: 12),
          _OpcionPublicar(
            icono: Icons.image_outlined,
            color: const Color(0xFF00B37E),
            titulo: 'Banner',
            subtitulo: 'Imagen destacada en el inicio',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CrearBannerScreen()));
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _OpcionPublicar extends StatelessWidget {
  final IconData icono;
  final Color color;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  const _OpcionPublicar({
    required this.icono,
    required this.color,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icono, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                Text(subtitulo,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey[500])),
              ],
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FEED PRINCIPAL
// ─────────────────────────────────────────────────────────────────────────────

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  final PublicacionesService _pubService = PublicacionesService();
  final HistoriasService _historiasService = HistoriasService();
  final BannersService _bannersService = BannersService();
  final ReportesService _reportesService = ReportesService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildBanners()),
          SliverToBoxAdapter(child: _buildHistorias()),
          SliverToBoxAdapter(child: _buildSeparador('Publicaciones')),
          _buildPublicaciones(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF005DB9), Color(0xFF009BDF)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.groups_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Text('Comunidad',
              style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF005DB9))),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.search_rounded, color: Color(0xFF005DB9)),
        ),
        Stack(
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_outlined, color: Color(0xFF005DB9)),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFF32836),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: Colors.grey[100]),
      ),
    );
  }

  Widget _buildBanners() {
    return StreamBuilder<List<BannerModel>>(
      stream: _bannersService.obtenerActivos(),
      builder: (context, snap) {
        final banners = snap.data ?? [];
        if (banners.isEmpty) return const SizedBox.shrink();
        return _CarruselBanners(banners: banners);
      },
    );
  }

  Widget _buildHistorias() {
    return StreamBuilder<List<HistoriaModel>>(
      stream: _historiasService.obtenerActivas(),
      builder: (context, snap) {
        final historias = snap.data ?? [];
        return _SeccionHistorias(historias: historias);
      },
    );
  }

  Widget _buildSeparador(String titulo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Text(titulo,
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2E))),
          const Spacer(),
          Text('Ver todo',
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF005DB9),
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildPublicaciones() {
    return StreamBuilder<List<PublicacionModel>>(
      stream: _pubService.obtenerPublicadas(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        final pubs = snap.data ?? [];
        if (pubs.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.article_outlined, size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text('Sin publicaciones aún',
                      style: GoogleFonts.poppins(color: Colors.grey[400])),
                ],
              ),
            ),
          );
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, i) => PublicacionCard(
              publicacion: pubs[i],
              onReportar: () => _reportar(pubs[i]),
            ),
            childCount: pubs.length,
          ),
        );
      },
    );
  }

  void _reportar(PublicacionModel pub) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ModalReporte(
        onReportar: (motivo, detalle) async {
          await _reportesService.reportar(
            tipo: 'publicacion',
            contenidoId: pub.id!,
            motivo: motivo,
            detalles: detalle,
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CARRUSEL DE BANNERS
// ─────────────────────────────────────────────────────────────────────────────

class _CarruselBanners extends StatefulWidget {
  final List<BannerModel> banners;
  const _CarruselBanners({required this.banners});

  @override
  State<_CarruselBanners> createState() => _CarruselBannersState();
}

class _CarruselBannersState extends State<_CarruselBanners> {
  final PageController _controller = PageController(viewportFraction: 0.92);
  int _paginaActual = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.banners.length,
            onPageChanged: (i) => setState(() => _paginaActual = i),
            itemBuilder: (_, i) {
              final b = widget.banners[i];
              return AnimatedScale(
                scale: _paginaActual == i ? 1.0 : 0.95,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: const Color(0xFF005DB9),
                    image: b.urlImagen.isNotEmpty
                        ? DecorationImage(
                      image: NetworkImage(b.urlImagen),
                      fit: BoxFit.cover,
                    )
                        : null,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                    alignment: Alignment.bottomLeft,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b.titulo,
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                        if (b.subtitulo != null && b.subtitulo!.isNotEmpty)
                          Text(b.subtitulo!,
                              style: GoogleFonts.poppins(
                                  color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.banners.length,
                (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _paginaActual == i ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _paginaActual == i
                    ? const Color(0xFF005DB9)
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECCIÓN HISTORIAS
// ─────────────────────────────────────────────────────────────────────────────

class _SeccionHistorias extends StatelessWidget {
  final List<HistoriaModel> historias;
  const _SeccionHistorias({required this.historias});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text('Historias',
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2E))),
        ),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              // Botón agregar historia
              _ItemHistoria(
                esAgregar: true,
                onTap: () {
                  // Navigator.push para crear historia
                },
              ),
              ...historias.map((h) => _ItemHistoria(historia: h)),
            ],
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _ItemHistoria extends StatelessWidget {
  final HistoriaModel? historia;
  final bool esAgregar;
  final VoidCallback? onTap;

  const _ItemHistoria({this.historia, this.esAgregar = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => _verHistoria(context),
      child: Container(
        width: 72,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: esAgregar
                    ? const LinearGradient(
                  colors: [Color(0xFF005DB9), Color(0xFF009BDF)],
                )
                    : const LinearGradient(
                  colors: [Color(0xFFF32836), Color(0xFFFF6B35)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(2.5),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                padding: const EdgeInsets.all(2),
                child: esAgregar
                    ? Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFF5F6FA),
                  ),
                  child: const Icon(Icons.add_rounded,
                      color: Color(0xFF005DB9), size: 24),
                )
                    : CircleAvatar(
                  backgroundImage: historia!.avatarUsuario.isNotEmpty
                      ? NetworkImage(historia!.avatarUsuario)
                      : null,
                  backgroundColor: const Color(0xFF005DB9),
                  child: historia!.avatarUsuario.isEmpty
                      ? Text(
                    historia!.nombreUsuario.isNotEmpty
                        ? historia!.nombreUsuario[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              esAgregar
                  ? 'Tu historia'
                  : historia!.nombreUsuario.split(' ').first,
              style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1A1A2E)),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _verHistoria(BuildContext context) {
    if (historia == null) return;
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => _VisorHistoria(historia: historia!),
    );
  }
}

class _VisorHistoria extends StatelessWidget {
  final HistoriaModel historia;
  const _VisorHistoria({required this.historia});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Center(
              child: historia.urlMedia.isNotEmpty
                  ? Image.network(historia.urlMedia, fit: BoxFit.contain)
                  : const Icon(Icons.image_not_supported,
                  color: Colors.white, size: 60),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: historia.avatarUsuario.isNotEmpty
                          ? NetworkImage(historia.avatarUsuario)
                          : null,
                      child: historia.avatarUsuario.isEmpty
                          ? Text(historia.nombreUsuario[0])
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(historia.nombreUsuario,
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                        Text('Hace un momento',
                            style: GoogleFonts.poppins(
                                color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ),
            if (historia.texto.isNotEmpty)
              Positioned(
                bottom: 40,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(historia.texto,
                      style: GoogleFonts.poppins(
                          color: Colors.white, fontSize: 14),
                      textAlign: TextAlign.center),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MODAL REPORTE
// ─────────────────────────────────────────────────────────────────────────────

class _ModalReporte extends StatefulWidget {
  final Future<void> Function(String motivo, String detalle) onReportar;
  const _ModalReporte({required this.onReportar});

  @override
  State<_ModalReporte> createState() => _ModalReporteState();
}

class _ModalReporteState extends State<_ModalReporte> {
  String _motivoSeleccionado = 'Contenido inapropiado';
  final _detalleController = TextEditingController();
  bool _enviando = false;

  final _motivos = [
    'Contenido inapropiado',
    'Spam',
    'Información falsa',
    'Acoso o bullying',
    'Otro',
  ];

  @override
  void dispose() {
    _detalleController.dispose();
    super.dispose();
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
            Text('Reportar publicación',
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ..._motivos.map((m) => RadioListTile<String>(
              value: m,
              groupValue: _motivoSeleccionado,
              onChanged: (v) => setState(() => _motivoSeleccionado = v!),
              title: Text(m, style: GoogleFonts.poppins(fontSize: 14)),
              activeColor: const Color(0xFF005DB9),
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            )),
            const SizedBox(height: 8),
            TextField(
              controller: _detalleController,
              decoration: InputDecoration(
                hintText: 'Detalles adicionales (opcional)',
                hintStyle: GoogleFonts.poppins(fontSize: 13),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.all(12),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _enviando
                    ? null
                    : () async {
                  setState(() => _enviando = true);
                  await widget.onReportar(
                    _motivoSeleccionado,
                    _detalleController.text,
                  );
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