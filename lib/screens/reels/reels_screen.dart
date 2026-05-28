import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../services/reels/reels_service.dart';
import '../../services/reports/report_service.dart';
import '../../models/reel_model.dart';
import '../../config/user_config.dart';
import '../../widgets/comment_sheet.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  List<ReelModel> _reels = [];
  bool _isLoading = true;
  final ReelsService _reelsService = ReelsService();
  final ReportService _reportService = ReportService();

  final Map<int, VideoPlayerController?> _videoControllers = {};
  final Map<int, ChewieController?> _chewieControllers = {};
  final Map<int, bool> _isLikedMap = {};
  final Map<int, bool> _isLoadingVideo = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadReels();
  }

  Future<void> _loadReels() async {
    final newReels = await _reelsService.getReels(limit: 10);

    setState(() {
      _reels = newReels;
      _isLoading = false;
    });

    // Precargar primeros 3 videos
    for (int i = 0; i < (_reels.length > 3 ? 3 : _reels.length); i++) {
      _preloadVideo(i);
    }
  }

  void _preloadVideo(int index) async {
    if (index >= _reels.length) return;
    if (_videoControllers[index] != null) return;
    if (_isLoadingVideo[index] == true) return;

    _isLoadingVideo[index] = true;
    if (mounted) setState(() {});

    final reel = _reels[index];

    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(reel.videoUrl),
      );

      await controller.initialize();
      _videoControllers[index] = controller;

      if (index == _currentPage) {
        _createChewieController(index);
      }

      _isLoadingVideo[index] = false;
      if (mounted) setState(() {});
    } catch (e) {
      print('Error precargando video $index: $e');
      _isLoadingVideo[index] = false;
      if (mounted) setState(() {});
    }
  }

  void _createChewieController(int index) {
    if (_chewieControllers[index] != null) return;

    final controller = _videoControllers[index];
    if (controller == null || !controller.value.isInitialized) return;

    _chewieControllers[index] = ChewieController(
      videoPlayerController: controller,
      autoPlay: true,
      looping: true,
      aspectRatio: 9 / 16,
      showControls: false,
      allowFullScreen: false,
      autoInitialize: true,
    );

    if (mounted) setState(() {});
  }

  void _onPageChanged(int index) async {
    // Pausar video anterior
    if (_currentPage >= 0 && _chewieControllers[_currentPage] != null) {
      _chewieControllers[_currentPage]!.pause();
    }

    setState(() {
      _currentPage = index;
    });

    // Reproducir video actual
    if (_chewieControllers[index] != null) {
      _chewieControllers[index]!.play();
    } else if (_videoControllers[index] != null) {
      _createChewieController(index);
    } else {
      _preloadVideo(index);
    }

    // Precargar siguiente video
    if (index + 1 < _reels.length && _videoControllers[index + 1] == null) {
      _preloadVideo(index + 1);
    }

    // Precargar anterior video
    if (index - 1 >= 0 && _videoControllers[index - 1] == null) {
      _preloadVideo(index - 1);
    }

    // Registrar vista
    if (_reels.isNotEmpty && index < _reels.length) {
      _reelsService.incrementViews(_reels[index].id!);
    }

    // Verificar like status
    if (index < _reels.length && _reels[index].id != null) {
      final isLiked = await _reelsService.isLiked(_reels[index].id!);
      if (mounted) {
        setState(() {
          _isLikedMap[index] = isLiked;
        });
      }
    }
  }

  Future<void> _toggleLike(int index) async {
    if (index >= _reels.length || _reels[index].id == null) return;

    final reel = _reels[index];
    await _reelsService.likeReel(reel.id!);

    final isLiked = await _reelsService.isLiked(reel.id!);
    setState(() {
      _isLikedMap[index] = isLiked;
      if (isLiked) {
        _reels[index].likes++;
      } else {
        _reels[index].likes--;
      }
    });
  }

  void _showReportDialog(String reelId) {
    final reasonController = TextEditingController();
    String selectedReason = 'Contenido inapropiado';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
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
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Reportar contenido',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              '¿Por qué estás reportando este reel?',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedReason,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'Contenido inapropiado', child: Text('Contenido inapropiado')),
                DropdownMenuItem(value: 'Spam', child: Text('Spam')),
                DropdownMenuItem(value: 'Discurso de odio', child: Text('Discurso de odio')),
                DropdownMenuItem(value: 'Acoso', child: Text('Acoso')),
                DropdownMenuItem(value: 'Información falsa', child: Text('Información falsa')),
                DropdownMenuItem(value: 'Violencia', child: Text('Violencia')),
              ],
              onChanged: (value) {
                selectedReason = value!;
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Detalles adicionales (opcional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancelar', style: GoogleFonts.poppins()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await _reportService.reportReel(
                        reelId: reelId,
                        reason: selectedReason,
                        details: reasonController.text.trim().isEmpty ? null : reasonController.text.trim(),
                      );
                      Navigator.pop(context);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Reporte enviado. Gracias por ayudar a mantener la comunidad segura.'),
                            backgroundColor: Color(0xFFF32836),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF32836),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Enviar reporte', style: GoogleFonts.poppins(color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _chewieControllers.values) {
      controller?.dispose();
    }
    for (var controller in _videoControllers.values) {
      controller?.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF005DB9)),
              ),
              SizedBox(height: 16),
              Text('Cargando reels...'),
            ],
          ),
        ),
      );
    }

    if (_reels.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text('No hay reels disponibles'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        onPageChanged: _onPageChanged,
        itemCount: _reels.length,
        itemBuilder: (context, index) {
          final reel = _reels[index];
          final isLiked = _isLikedMap[index] ?? false;
          final hasVideo = _chewieControllers[index] != null;
          final isLoading = _isLoadingVideo[index] == true;

          return Stack(
            children: [
              // Video
              Positioned.fill(
                child: hasVideo
                    ? Chewie(controller: _chewieControllers[index]!)
                    : Container(
                  color: Colors.black,
                  child: isLoading
                      ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 12),
                        Text(
                          'Cargando...',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  )
                      : null,
                ),
              ),
              // Overlay de información
              Positioned(
                bottom: 80,
                left: 16,
                right: 60,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reel.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(blurRadius: 10, color: Colors.black26)],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reel.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        shadows: [Shadow(blurRadius: 10, color: Colors.black26)],
                      ),
                    ),
                  ],
                ),
              ),
              // Barra lateral de acciones
              Positioned(
                bottom: 80,
                right: 16,
                child: Column(
                  children: [
                    _buildActionButton(
                      icon: Icons.favorite,
                      count: reel.likes,
                      isActive: isLiked,
                      activeColor: const Color(0xFFF32836),
                      onTap: () => _toggleLike(index),
                    ),
                    const SizedBox(height: 20),
                    _buildActionButton(
                      icon: Icons.chat_bubble_outline,
                      count: reel.comments,
                      isActive: false,
                      activeColor: Colors.white,
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (context) => CommentsSheet(
                            reelId: reel.id!,
                            initialCommentsCount: reel.comments,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Header de usuario
              Positioned(
                top: 48,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFF009BDF),
                        backgroundImage: reel.userAvatar.isNotEmpty
                            ? NetworkImage(reel.userAvatar)
                            : null,
                        child: reel.userAvatar.isEmpty
                            ? const Icon(Icons.person, color: Colors.white, size: 18)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        reel.userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          shadows: [Shadow(blurRadius: 10, color: Colors.black26)],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _getGroupColor(reel.groupId),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getGroupName(reel.groupId),
                        style: const TextStyle(color: Colors.white, fontSize: 9),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                      color: Colors.white,
                      onSelected: (value) {
                        if (value == 'report') {
                          _showReportDialog(reel.id!);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'report',
                          child: Row(
                            children: [
                              Icon(Icons.flag, color: Color(0xFFF32836), size: 20),
                              SizedBox(width: 8),
                              Text('Reportar'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required int count,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive ? activeColor : Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _formatCount(count),
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  Color _getGroupColor(String groupId) {
    switch (groupId) {
      case 'cultura':
        return const Color(0xFF005DB9);
      case 'anuncios':
        return const Color(0xFF009BDF);
      case 'capacitacion':
        return const Color(0xFFF32836);
      default:
        return const Color(0xFF005DB9);
    }
  }

  String _getGroupName(String groupId) {
    switch (groupId) {
      case 'cultura':
        return 'Cultura';
      case 'anuncios':
        return 'Anuncios';
      case 'capacitacion':
        return 'Capacitación';
      default:
        return groupId;
    }
  }
}