import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/usuario_config.dart';
import '../../models/publicacion_model.dart';
import '../../services/publicaciones/publicaciones_service.dart';
import '../../widgets/publicacion_card.dart';
import '../../services/reportes/reportes_service.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PerfilContenido();
  }
}

// También se puede abrir desde el menú con datos del usuario actual
class PerfilDetalleScreen extends StatelessWidget {
  const PerfilDetalleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PerfilContenido(mostrarBack: true);
  }
}

class _PerfilContenido extends StatefulWidget {
  final bool mostrarBack;
  const _PerfilContenido({this.mostrarBack = false});

  @override
  State<_PerfilContenido> createState() => _PerfilContenidoState();
}

class _PerfilContenidoState extends State<_PerfilContenido>
    with SingleTickerProviderStateMixin {
  final PublicacionesService _pubService = PublicacionesService();
  final ReportesService _reportesService = ReportesService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildAppBar(innerBoxIsScrolled),
          SliverToBoxAdapter(child: _buildEncabezadoPerfil()),
          SliverToBoxAdapter(child: _buildEstadisticas()),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                labelStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, fontSize: 13),
                unselectedLabelStyle:
                GoogleFonts.poppins(fontSize: 13),
                labelColor: const Color(0xFF005DB9),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF005DB9),
                indicatorWeight: 2.5,
                tabs: const [
                  Tab(text: 'Publicaciones'),
                  Tab(text: 'Menciones'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildTabPublicaciones(),
            _buildTabMenciones(),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(bool innerBoxIsScrolled) {
    return SliverAppBar(
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: widget.mostrarBack
          ? IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded,
            color: Color(0xFF005DB9)),
        onPressed: () => Navigator.pop(context),
      )
          : null,
      automaticallyImplyLeading: widget.mostrarBack,
      title: Text(
        widget.mostrarBack ? UsuarioConfig.nombreUsuario : 'Mi perfil',
        style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A2E)),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: Colors.grey[100]),
      ),
    );
  }

  Widget _buildEncabezadoPerfil() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF005DB9), Color(0xFF009BDF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.all(3),
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: Colors.white,
                  backgroundImage: UsuarioConfig.avatarUsuario.isNotEmpty
                      ? NetworkImage(UsuarioConfig.avatarUsuario)
                      : null,
                  child: UsuarioConfig.avatarUsuario.isEmpty
                      ? Text(
                    UsuarioConfig.nombreUsuario.isNotEmpty
                        ? UsuarioConfig.nombreUsuario[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF005DB9)),
                  )
                      : null,
                ),
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF005DB9),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      size: 12, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  UsuarioConfig.nombreUsuario,
                  style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A2E)),
                ),
                const SizedBox(height: 3),
                Text(
                  UsuarioConfig.puestoUsuario,
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 3),
                Text(
                  UsuarioConfig.departamento,
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _PillInfo(
                      texto: UsuarioConfig.rol.toUpperCase(),
                      color: const Color(0xFF005DB9),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadisticas() {
    return StreamBuilder<List<PublicacionModel>>(
      stream: _pubService.obtenerPublicadas(),
      builder: (context, snap) {
        final pubs = snap.data ?? [];
        final misPubs = pubs
            .where((p) => p.usuarioId == UsuarioConfig.usuarioId)
            .toList();
        final totalLikes =
        misPubs.fold<int>(0, (sum, p) => sum + p.likes);
        final totalComentarios =
        misPubs.fold<int>(0, (sum, p) => sum + p.comentarios);

        return Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Row(
            children: [
              _StatItem(
                  valor: '${misPubs.length}', etiqueta: 'Publicaciones'),
              _buildDivisorVertical(),
              _StatItem(valor: '$totalLikes', etiqueta: 'Likes'),
              _buildDivisorVertical(),
              _StatItem(
                  valor: '$totalComentarios', etiqueta: 'Comentarios'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDivisorVertical() {
    return Container(
        width: 1, height: 36, color: Colors.grey[200],
        margin: const EdgeInsets.symmetric(horizontal: 16));
  }

  Widget _buildTabPublicaciones() {
    return StreamBuilder<List<PublicacionModel>>(
      stream: _pubService.obtenerPublicadas(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final pubs = (snap.data ?? [])
            .where((p) => p.usuarioId == UsuarioConfig.usuarioId)
            .toList();

        if (pubs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.article_outlined,
                    size: 64, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text('Aún no tienes publicaciones',
                    style: GoogleFonts.poppins(
                        color: Colors.grey[400], fontSize: 15)),
                const SizedBox(height: 8),
                Text('¡Comparte algo con tu comunidad!',
                    style: GoogleFonts.poppins(
                        color: Colors.grey[400], fontSize: 13)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          itemCount: pubs.length,
          itemBuilder: (context, i) => PublicacionCard(
            publicacion: pubs[i],
            onReportar: () async {
              await _reportesService.reportar(
                tipo: 'publicacion',
                contenidoId: pubs[i].id!,
                motivo: 'Reporte desde perfil',
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTabMenciones() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.alternate_email_rounded,
              size: 64, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text('Sin menciones aún',
              style: GoogleFonts.poppins(
                  color: Colors.grey[400], fontSize: 15)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGETS AUXILIARES
// ─────────────────────────────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  final String valor;
  final String etiqueta;

  const _StatItem({required this.valor, required this.etiqueta});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(valor,
              style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2E))),
          Text(etiqueta,
              style: GoogleFonts.poppins(
                  fontSize: 11, color: Colors.grey[500])),
        ],
      ),
    );
  }
}

class _PillInfo extends StatelessWidget {
  final String texto;
  final Color color;

  const _PillInfo({required this.texto, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto,
        style: GoogleFonts.poppins(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}

// Delegate para el TabBar sticky
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}