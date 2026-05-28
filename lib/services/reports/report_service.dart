import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/user_config.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference get _reportsCollection => _firestore.collection('reports');
  CollectionReference get _reelsCollection => _firestore.collection('reels');

  // Reportar un reel
  Future<void> reportReel({
    required String reelId,
    required String reason,
    String? details,
  }) async {
    final report = {
      'type': 'reel',
      'contentId': reelId,
      'reporterId': UserConfig.currentUserId,
      'reporterName': UserConfig.currentUserName,
      'reason': reason,
      'details': details ?? '',
      'status': 'pending', // pending, reviewed, dismissed
      'createdAt': Timestamp.now(),
    };

    await _reportsCollection.add(report);
  }

  // Reportar una publicación
  Future<void> reportPost({
    required String postId,
    required String reason,
    String? details,
  }) async {
    final report = {
      'type': 'post',
      'contentId': postId,
      'reporterId': UserConfig.currentUserId,
      'reporterName': UserConfig.currentUserName,
      'reason': reason,
      'details': details ?? '',
      'status': 'pending',
      'createdAt': Timestamp.now(),
    };

    await _reportsCollection.add(report);
  }

  // Obtener reportes pendientes
  Stream<List<Map<String, dynamic>>> getPendingReports() {
    return _reportsCollection
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Eliminar un reel y sus reportes asociados
  Future<void> deleteReelAndReports(String reelId, String reportId) async {
    try {
      // 1. Eliminar el reel de la colección principal
      final reelDoc = await _reelsCollection.doc(reelId).get();
      if (reelDoc.exists) {
        await _reelsCollection.doc(reelId).delete();
      }

      // 2. Verificar si también existe en reels-dev (pendientes)
      final reelsDevCollection = _firestore.collection('reels-dev');
      final devDoc = await reelsDevCollection.doc(reelId).get();
      if (devDoc.exists) {
        await reelsDevCollection.doc(reelId).delete();
      }

      // 3. Eliminar comentarios asociados al reel
      final commentsSnapshot = await _firestore
          .collection('reels_comments')
          .where('reelId', isEqualTo: reelId)
          .get();

      for (final doc in commentsSnapshot.docs) {
        await doc.reference.delete();
      }

      // 4. Marcar el reporte como revisado y guardar que se eliminó
      await _reportsCollection.doc(reportId).update({
        'status': 'reviewed',
        'reviewedAt': Timestamp.now(),
        'reviewedBy': UserConfig.currentUserId,
        'actionTaken': 'deleted',
      });

      // 5. Marcar otros reportes del mismo contenido como resueltos
      final otherReports = await _reportsCollection
          .where('contentId', isEqualTo: reelId)
          .where('status', isEqualTo: 'pending')
          .get();

      for (final doc in otherReports.docs) {
        await doc.reference.update({
          'status': 'reviewed',
          'reviewedAt': Timestamp.now(),
          'reviewedBy': UserConfig.currentUserId,
          'actionTaken': 'deleted',
        });
      }
    } catch (e) {
      print('Error deleting reel: $e');
      rethrow;
    }
  }

  // Marcar reporte como ignorado (sin eliminar)
  Future<void> dismissReport(String reportId, String contentId) async {
    try {
      // Marcar este reporte como ignorado
      await _reportsCollection.doc(reportId).update({
        'status': 'dismissed',
        'reviewedAt': Timestamp.now(),
        'reviewedBy': UserConfig.currentUserId,
        'actionTaken': 'ignored',
      });

      // Marcar otros reportes del mismo contenido como ignorados
      final otherReports = await _reportsCollection
          .where('contentId', isEqualTo: contentId)
          .where('status', isEqualTo: 'pending')
          .get();

      for (final doc in otherReports.docs) {
        await doc.reference.update({
          'status': 'dismissed',
          'reviewedAt': Timestamp.now(),
          'reviewedBy': UserConfig.currentUserId,
          'actionTaken': 'ignored',
        });
      }
    } catch (e) {
      print('Error dismissing report: $e');
      rethrow;
    }
  }
}