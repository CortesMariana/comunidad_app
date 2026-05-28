import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/reel_model.dart';

class ControlContenidoAprobados extends StatelessWidget {
  const ControlContenidoAprobados({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ReelModel>>(
      stream: _getApprovedReelsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final reels = snapshot.data ?? [];

        if (reels.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 60, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No hay reels aprobados recientemente',
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
            final reel = reels[index];
            return _buildApprovedReelCard(reel);
          },
        );
      },
    );
  }

  Stream<List<ReelModel>> _getApprovedReelsStream() {
    return FirebaseFirestore.instance
        .collection('reels')
        .where('status', isEqualTo: 'approved')
        .orderBy('approvedAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ReelModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  Widget _buildApprovedReelCard(ReelModel reel) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                  Text(_formatDate(reel.approvedAt ?? reel.createdAt), style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500])),
                  const SizedBox(height: 4),
                  Text(
                    reel.title,
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF005DB9).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check, size: 12, color: Color(0xFF005DB9)),
                  const SizedBox(width: 4),
                  Text('Aprobado', style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF005DB9))),
                ],
              ),
            ),
          ],
        ),
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
    } else {
      return 'hace ${difference.inMinutes} minutos';
    }
  }
}