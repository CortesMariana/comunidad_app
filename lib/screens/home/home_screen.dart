import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/posts/posts_service.dart';
import '../../services/reports/report_service.dart';
import '../../services/stories/story_service.dart';
import '../../models/post_model.dart';
import '../../models/story_model.dart';
import '../../widgets/publication_card.dart';
import '../reels/reels_screen.dart';
import '../notifications/notifications_screen.dart';
import '../menu/menu_screen.dart';
import '../profile/profile_screen.dart';
import '../crear_contenido/crear_contenido_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeFeedScreen(),
    const ReelsScreen(),
    const NotificationsScreen(),
    const MenuScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          selectedItemColor: const Color(0xFF005DB9),
          unselectedItemColor: Colors.grey[400],
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.slow_motion_video_outlined), label: 'Reels'),
            BottomNavigationBarItem(icon: Icon(Icons.notifications_none), label: 'Notificaciones'),
            BottomNavigationBarItem(icon: Icon(Icons.grid_view_outlined), label: 'Menú'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Perfil'),
          ],
        ),
      ),
    );
  }
}

// Pantalla de feed de Home
class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  final PostsService _postsService = PostsService();
  final ReportService _reportService = ReportService();
  final StoryService _storyService = StoryService();

  List<PostModel> _posts = [];
  bool _isLoading = true;

  final List<Map<String, String>> _noticiasCarrusel = const [
    {'titulo': '📢 Nuevo proyecto 2026', 'fondo': '#005DB9'},
    {'titulo': '🎉 Fiesta de fin de año', 'fondo': '#009BDF'},
    {'titulo': '🏆 Reconocimiento al equipo', 'fondo': '#F32836'},
    {'titulo': '💻 Actualización del sistema', 'fondo': '#005DB9'},
    {'titulo': '🌟 Nuevos beneficios', 'fondo': '#009BDF'},
  ];

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
    });

    final newPosts = await _postsService.getApprovedPosts(limit: 20);

    setState(() {
      _posts = newPosts;
      _isLoading = false;
    });
  }

  void _reportPost(String postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        String selectedReason = 'Contenido inapropiado';
        final reasonController = TextEditingController();

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Reportar publicación',
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedReason,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: const [
                  DropdownMenuItem(value: 'Contenido inapropiado', child: Text('Contenido inapropiado')),
                  DropdownMenuItem(value: 'Spam', child: Text('Spam')),
                  DropdownMenuItem(value: 'Discurso de odio', child: Text('Discurso de odio')),
                  DropdownMenuItem(value: 'Acoso', child: Text('Acoso')),
                ],
                onChanged: (value) => selectedReason = value!,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: 'Detalles adicionales (opcional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await _reportService.reportPost(
                          postId: postId,
                          reason: selectedReason,
                          details: reasonController.text.trim().isEmpty ? null : reasonController.text.trim(),
                        );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Reporte enviado'),
                            backgroundColor: Color(0xFFF32836),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF32836),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Enviar reporte'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadPosts,
        child: CustomScrollView(
          slivers: [
            // Espacio superior
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Carrusel de noticias
            SliverToBoxAdapter(child: _buildCarouselNoticias()),

            // Banner informativo
            SliverToBoxAdapter(child: _buildBannerInformativo()),

            // Historias
            SliverToBoxAdapter(child: _buildHistorias()),

            // Publicaciones
            if (_isLoading)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
              )
            else if (_posts.isEmpty)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No hay publicaciones'),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) => PublicationCard(
                    post: _posts[index],
                    onReport: () => _reportPost(_posts[index].id!),
                  ),
                  childCount: _posts.length,
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CrearContenidoScreen()),
          );
        },
        backgroundColor: const Color(0xFF005DB9),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCarouselNoticias() {
    return SizedBox(
      height: 120,
      child: PageView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _noticiasCarrusel.length,
        itemBuilder: (context, index) {
          final noticia = _noticiasCarrusel[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            width: MediaQuery.of(context).size.width - 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(int.parse(noticia['fondo']!.replaceFirst('#', '0xFF'))),
                  Color(int.parse(noticia['fondo']!.replaceFirst('#', '0xFF'))).withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Color(int.parse(noticia['fondo']!.replaceFirst('#', '0xFF'))).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                noticia['titulo']!,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBannerInformativo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            color: const Color(0xFF005DB9).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.info_outline, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📢 ¡Importante!',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Nuevo proyecto anunciado para el próximo mes. Mantente atento a las novedades.',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Válido hasta: 30/06',
              style: GoogleFonts.poppins(
                color: const Color(0xFF005DB9),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorias() {
    return StreamBuilder<List<StoryModel>>(
      stream: _storyService.getActiveStories(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final stories = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Historias', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: stories.length,
                itemBuilder: (context, index) {
                  final story = stories[index];
                  return GestureDetector(
                    onTap: () => _mostrarHistoria(story),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF005DB9), Color(0xFF009BDF)],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: CircleAvatar(
                                radius: 32,
                                backgroundImage: NetworkImage(story.userAvatar),
                                onBackgroundImageError: (_, __) {},
                                child: story.userAvatar.isEmpty
                                    ? const Icon(Icons.person, size: 32)
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            story.userName.split(' ').first,
                            style: GoogleFonts.poppins(fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _mostrarHistoria(StoryModel story) async {
    await _storyService.markAsViewed(story.id!);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          height: 500,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF005DB9), Color(0xFF009BDF)],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              const SizedBox(height: 40),
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(story.userAvatar),
                onBackgroundImageError: (_, __) {},
                child: story.userAvatar.isEmpty
                    ? const Icon(Icons.person, size: 50, color: Colors.white)
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                story.userName,
                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _formatStoryDate(story.createdAt),
                  style: GoogleFonts.poppins(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: story.type == 'image'
                        ? Image.network(story.mediaUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Center(child: Icon(Icons.broken_image, size: 50)),
                      );
                    })
                        : const Center(child: Icon(Icons.video_library, size: 50)),
                  ),
                ),
              ),
              if (story.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    story.text,
                    style: GoogleFonts.poppins(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _formatStoryDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inHours < 1) return 'hace ${diff.inMinutes} minutos';
    if (diff.inHours < 24) return 'hace ${diff.inHours} horas';
    return 'hace ${diff.inDays} días';
  }
}