import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/reels/reels_service.dart';
import '../../../services/posts/posts_service.dart';
import '../../../services/stories/story_service.dart';
import '../../../models/reel_model.dart';
import '../../../models/post_model.dart';
import '../../../models/story_model.dart';
import '../../../config/user_config.dart';

class ControlContenidoPendientes extends StatefulWidget {
  const ControlContenidoPendientes({super.key});

  @override
  State<ControlContenidoPendientes> createState() => _ControlContenidoPendientesState();
}

class _ControlContenidoPendientesState extends State<ControlContenidoPendientes>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ReelsService _reelsService = ReelsService();
  final PostsService _postsService = PostsService();
  final StoryService _storyService = StoryService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Reels', icon: Icon(Icons.slow_motion_video)),
            Tab(text: 'Publicaciones', icon: Icon(Icons.post_add)),
            Tab(text: 'Historias', icon: Icon(Icons.history)),
          ],
          labelColor: const Color(0xFF005DB9),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF005DB9),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildReelsPendientes(),
              _buildPostsPendientes(),
              _buildStoriesPendientes(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReelsPendientes() {
    return StreamBuilder<List<ReelModel>>(
      stream: _getPendingReelsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final reels = snapshot.data ?? [];

        if (reels.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pending_outlined, size: 60, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No hay reels pendientes',
                  style: GoogleFonts.poppins(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reels.length,
          itemBuilder: (context, index) {
            return _buildPendingReelCard(reels[index]);
          },
        );
      },
    );
  }

  Widget _buildPostsPendientes() {
    return StreamBuilder<List<PostModel>>(
      stream: _postsService.getPendingPosts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final posts = snapshot.data ?? [];

        if (posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pending_outlined, size: 60, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No hay publicaciones pendientes',
                  style: GoogleFonts.poppins(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            return _buildPendingPostCard(posts[index]);
          },
        );
      },
    );
  }

  Widget _buildStoriesPendientes() {
    return StreamBuilder<List<StoryModel>>(
      stream: _storyService.getPendingStories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final stories = snapshot.data ?? [];

        if (stories.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pending_outlined, size: 60, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No hay historias pendientes',
                  style: GoogleFonts.poppins(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: stories.length,
          itemBuilder: (context, index) {
            return _buildPendingStoryCard(stories[index]);
          },
        );
      },
    );
  }

  Stream<List<ReelModel>> _getPendingReelsStream() {
    return FirebaseFirestore.instance
        .collection('reels-dev')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ReelModel.fromMap(doc.id, data);
      }).toList();
    });
  }

  Widget _buildPendingReelCard(ReelModel reel) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: reel.userAvatar.isNotEmpty
                      ? NetworkImage(reel.userAvatar)
                      : null,
                  child: reel.userAvatar.isEmpty
                      ? Text(reel.userName[0].toUpperCase())
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(reel.userName, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      Text(_formatDate(reel.createdAt), style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[500])),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Pendiente', style: GoogleFonts.poppins(fontSize: 10, color: Colors.orange)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(reel.title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 8),
          Container(
            height: 150,
            width: double.infinity,
            color: Colors.grey[900],
            child: const Center(child: Icon(Icons.video_library, size: 40, color: Colors.grey)),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _showRejectReelDialog(reel),
                  child: Text('Rechazar', style: GoogleFonts.poppins(color: Colors.grey[600])),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _approveReel(reel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF005DB9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Aprobar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingPostCard(PostModel post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: post.userAvatar.isNotEmpty
                      ? NetworkImage(post.userAvatar)
                      : null,
                  child: post.userAvatar.isEmpty
                      ? Text(post.userName[0].toUpperCase())
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.userName, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      Text(_formatDate(post.createdAt), style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[500])),
                      if (post.isScheduled && post.scheduledDate != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF009BDF).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Programada para: ${_formatScheduledDate(post.scheduledDate!)}',
                            style: GoogleFonts.poppins(fontSize: 9, color: const Color(0xFF009BDF)),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Pendiente', style: GoogleFonts.poppins(fontSize: 10, color: Colors.orange)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(post.content, style: GoogleFonts.poppins(fontSize: 14)),
          ),
          if (post.imageUrl != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                post.imageUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 180,
                    color: Colors.grey[200],
                    child: const Center(child: Icon(Icons.broken_image, size: 40)),
                  );
                },
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _showRejectPostDialog(post),
                  child: Text('Rechazar', style: GoogleFonts.poppins(color: Colors.grey[600])),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _approvePost(post),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF005DB9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Aprobar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingStoryCard(StoryModel story) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: story.userAvatar.isNotEmpty
                      ? NetworkImage(story.userAvatar)
                      : null,
                  child: story.userAvatar.isEmpty
                      ? Text(story.userName[0].toUpperCase())
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(story.userName, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      Text(_formatDate(story.createdAt), style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[500])),
                      Text(
                        'Expira: ${_formatExpiryDate(story.expiresAt)}',
                        style: GoogleFonts.poppins(fontSize: 9, color: Colors.red[300]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Pendiente', style: GoogleFonts.poppins(fontSize: 10, color: Colors.orange)),
                ),
              ],
            ),
          ),
          Container(
            height: 200,
            width: double.infinity,
            color: Colors.grey[200],
            child: story.type == 'image'
                ? Image.network(story.mediaUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) {
              return const Center(child: Icon(Icons.broken_image, size: 40));
            })
                : const Center(child: Icon(Icons.video_library, size: 40, color: Colors.grey)),
          ),
          if (story.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(story.text, style: GoogleFonts.poppins(fontSize: 12)),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _showRejectStoryDialog(story),
                  child: Text('Rechazar', style: GoogleFonts.poppins(color: Colors.grey[600])),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _approveStory(story),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF005DB9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Aprobar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approveReel(ReelModel reel) async {
    final success = await _reelsService.approveReel(reel.id!);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reel aprobado'), backgroundColor: Color(0xFF005DB9)),
      );
    }
  }

  Future<void> _approvePost(PostModel post) async {
    final success = await _postsService.approvePost(post.id!);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Publicación aprobada'), backgroundColor: Color(0xFF005DB9)),
      );
    }
  }

  Future<void> _approveStory(StoryModel story) async {
    final success = await _storyService.approveStory(story.id!);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Historia aprobada'), backgroundColor: Color(0xFF005DB9)),
      );
    }
  }

  void _showRejectReelDialog(ReelModel reel) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar reel'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(labelText: 'Motivo del rechazo'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              await _reelsService.rejectReel(reel.id!, reasonController.text.trim());
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reel rechazado'), backgroundColor: Color(0xFFF32836)),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF32836)),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
  }

  void _showRejectPostDialog(PostModel post) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar publicación'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(labelText: 'Motivo del rechazo'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              await _postsService.rejectPost(post.id!, reasonController.text.trim());
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Publicación rechazada'), backgroundColor: Color(0xFFF32836)),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF32836)),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
  }

  void _showRejectStoryDialog(StoryModel story) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar historia'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(labelText: 'Motivo del rechazo'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              await _storyService.rejectStory(story.id!, reasonController.text.trim());
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Historia rechazada'), backgroundColor: Color(0xFFF32836)),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF32836)),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 7) return '${date.day}/${date.month}/${date.year}';
    if (diff.inDays > 0) return 'hace ${diff.inDays} días';
    if (diff.inHours > 0) return 'hace ${diff.inHours} horas';
    return 'hace ${diff.inMinutes} minutos';
  }

  String _formatScheduledDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatExpiryDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}