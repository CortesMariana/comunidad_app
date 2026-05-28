import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/posts/posts_service.dart';
import '../models/post_model.dart';
import '../config/user_config.dart';

class PublicationCard extends StatefulWidget {
  final PostModel post;
  final VoidCallback? onReport;

  const PublicationCard({
    super.key,
    required this.post,
    this.onReport,
  });

  @override
  State<PublicationCard> createState() => _PublicationCardState();
}

class _PublicationCardState extends State<PublicationCard> {
  final PostsService _postsService = PostsService();
  bool _isLiked = false;
  int _likeCount = 0;
  String? _userReaction;
  bool _showComments = false;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _likeCount = widget.post.likes;
    _checkIfLiked();
    _getUserReaction();
  }

  Future<void> _checkIfLiked() async {
    final liked = await _postsService.isLiked(widget.post.id!);
    if (mounted) {
      setState(() {
        _isLiked = liked;
      });
    }
  }

  Future<void> _getUserReaction() async {
    final reaction = await _postsService.getUserReaction(widget.post.id!);
    if (mounted) {
      setState(() {
        _userReaction = reaction;
      });
    }
  }

  void _showReactionPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ReactionType.values.map((reaction) {
            return GestureDetector(
              onTap: () async {
                await _postsService.addReaction(widget.post.id!, reaction);
                Navigator.pop(context);
                setState(() {
                  _userReaction = reaction.value;
                });
              },
              child: Column(
                children: [
                  Text(reaction.emoji, style: const TextStyle(fontSize: 40)),
                  const SizedBox(height: 4),
                  Text(
                    reaction.value,
                    style: GoogleFonts.poppins(fontSize: 10),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showCommentsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.comment, color: Color(0xFF005DB9)),
                const SizedBox(width: 8),
                Text(
                  'Comentarios (${widget.post.comments})',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _postsService.getComments(widget.post.id!),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final comments = snapshot.data!;
                  if (comments.isEmpty) {
                    return Center(
                      child: Text(
                        'No hay comentarios aún',
                        style: GoogleFonts.poppins(color: Colors.grey[500]),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundImage: comment['userAvatar'] != null
                                  ? NetworkImage(comment['userAvatar'])
                                  : null,
                              child: comment['userAvatar'] == null
                                  ? Text(comment['userName'][0].toUpperCase())
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    comment['userName'],
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12),
                                  ),
                                  Text(
                                    comment['text'],
                                    style: GoogleFonts.poppins(fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Escribe un comentario...',
                      hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async {
                    if (_commentController.text.trim().isEmpty) return;
                    await _postsService.addComment(
                      widget.post.id!,
                      _commentController.text.trim(),
                    );
                    _commentController.clear();
                    setState(() {
                      widget.post.comments++;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF005DB9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: widget.post.userAvatar.isNotEmpty
                      ? NetworkImage(widget.post.userAvatar)
                      : null,
                  child: widget.post.userAvatar.isEmpty
                      ? Text(widget.post.userName[0].toUpperCase())
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.post.userName,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        _formatDate(widget.post.createdAt),
                        style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'report' && widget.onReport != null) {
                      widget.onReport!();
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
          // Contenido
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              widget.post.content,
              style: GoogleFonts.poppins(fontSize: 14),
            ),
          ),
          const SizedBox(height: 12),
          // Imagen
          if (widget.post.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                widget.post.imageUrl!,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 220,
                    color: Colors.grey[200],
                    child: const Center(child: Icon(Icons.broken_image, size: 50)),
                  );
                },
              ),
            ),
          // Acciones
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Reacción con emoji
                GestureDetector(
                  onTap: _showReactionPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _userReaction != null
                              ? ReactionType.values.firstWhere(
                                (e) => e.value == _userReaction,
                            orElse: () => ReactionType.like,
                          ).emoji
                              : '❤️',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _likeCount.toString(),
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Comentarios
                GestureDetector(
                  onTap: _showCommentsSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline, size: 16, color: Color(0xFF009BDF)),
                        const SizedBox(width: 4),
                        Text(
                          widget.post.comments.toString(),
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                // Compartir
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.share, size: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return 'hace ${difference.inDays} día${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'hace ${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'hace ${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'ahora';
    }
  }
}