import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/reels/reels_service.dart';
import '../models/comment_model.dart';
import '../config/user_config.dart';

class CommentsSheet extends StatefulWidget {
  final String reelId;
  final int initialCommentsCount;

  const CommentsSheet({
    super.key,
    required this.reelId,
    required this.initialCommentsCount,
  });

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final ReelsService _reelsService = ReelsService();
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final text = _commentController.text.trim();
    _commentController.clear();

    await _reelsService.addComment(widget.reelId, text);

    // Scroll al inicio para ver el nuevo comentario
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF005DB9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Comentarios (${widget.initialCommentsCount})',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Lista de comentarios
          Expanded(
            child: StreamBuilder<List<CommentModel>>(
              stream: _reelsService.getComments(widget.reelId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final comments = snapshot.data!;

                if (comments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 50, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'No hay comentarios aún',
                          style: GoogleFonts.poppins(color: Colors.grey[500]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sé el primero en comentar',
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final isOwnComment = comment.userId == UserConfig.currentUserId;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: comment.userAvatar.isNotEmpty
                                ? NetworkImage(comment.userAvatar)
                                : null,
                            child: comment.userAvatar.isEmpty
                                ? Text(comment.userName[0].toUpperCase())
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      comment.userName,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatDate(comment.createdAt),
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  comment.text,
                                  style: GoogleFonts.poppins(fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {},
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.favorite_border,
                                            size: 14,
                                            color: Colors.grey[500],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            comment.likes.toString(),
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      'Responder',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
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
          // Input de comentario
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
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
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _sendComment,
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