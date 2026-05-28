import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/story_model.dart';
import '../../config/user_config.dart';

class StoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _storiesCollection => _firestore.collection('historias');
  CollectionReference get _storiesDevCollection => _firestore.collection('historias-dev');

  // Obtener historias aprobadas y no expiradas para Home
  Stream<List<StoryModel>> getActiveStories() {
    final now = Timestamp.now();
    return _storiesCollection
        .where('status', isEqualTo: 'approved')
        .where('expiresAt', isGreaterThan: now)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return StoryModel.fromMap(doc.id, data);
      }).toList();
    });
  }

  // Obtener historias pendientes (para control de contenido)
  Stream<List<StoryModel>> getPendingStories() {
    return _storiesDevCollection
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return StoryModel.fromMap(doc.id, data);
      }).toList();
    });
  }

  // Crear historia (se guarda en historias-dev como pendiente)
  Future<String?> createStory(StoryModel story) async {
    try {
      final docRef = await _storiesDevCollection.add(story.toMap());

      // Notificar a moderadores
      await _createModeratorNotification(
        title: 'Nueva historia pendiente',
        message: '${story.userName} ha subido una nueva historia',
        type: 'pending_approval',
        relatedId: docRef.id,
      );

      return docRef.id;
    } catch (e) {
      print('Error creating story: $e');
      return null;
    }
  }

  // Aprobar historia
  Future<bool> approveStory(String storyId, {String? approvedBy}) async {
    try {
      final devDoc = await _storiesDevCollection.doc(storyId).get();
      if (!devDoc.exists) return false;

      final storyData = devDoc.data() as Map<String, dynamic>;
      storyData['status'] = 'approved';
      storyData['approvedAt'] = Timestamp.now();
      storyData['approvedBy'] = approvedBy ?? UserConfig.currentUserId;

      await _storiesCollection.add(storyData);
      await _storiesDevCollection.doc(storyId).delete();

      return true;
    } catch (e) {
      print('Error approving story: $e');
      return false;
    }
  }

  // Rechazar historia
  Future<bool> rejectStory(String storyId, String reason) async {
    try {
      final devDoc = await _storiesDevCollection.doc(storyId).get();
      if (!devDoc.exists) return false;

      // Notificar al creador
      final storyData = devDoc.data() as Map<String, dynamic>;
      await _createNotification(
        userId: storyData['userId'],
        title: 'Historia rechazada ❌',
        message: 'Tu historia ha sido rechazada. Motivo: $reason',
        type: 'rejection',
        relatedId: storyId,
      );

      await _storiesDevCollection.doc(storyId).delete();
      return true;
    } catch (e) {
      print('Error rejecting story: $e');
      return false;
    }
  }

  // Marcar historia como vista
  Future<void> markAsViewed(String storyId) async {
    final userId = UserConfig.currentUserId;
    final storyRef = _storiesCollection.doc(storyId);

    final doc = await storyRef.get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final viewedBy = List<String>.from(data['viewedBy'] ?? []);
      if (!viewedBy.contains(userId)) {
        await storyRef.update({
          'views': FieldValue.increment(1),
          'viewedBy': FieldValue.arrayUnion([userId]),
        });
      }
    }
  }

  Future<void> _createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? relatedId,
  }) async {
    final notification = {
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'relatedId': relatedId,
      'isRead': false,
      'createdAt': Timestamp.now(),
    };
    await _firestore.collection('notifications').add(notification);
  }

  Future<void> _createModeratorNotification({
    required String title,
    required String message,
    required String type,
    String? relatedId,
  }) async {
    final moderatorIds = ['temp_user_001'];
    for (final userId in moderatorIds) {
      await _createNotification(
        userId: userId,
        title: title,
        message: message,
        type: type,
        relatedId: relatedId,
      );
    }
  }
}