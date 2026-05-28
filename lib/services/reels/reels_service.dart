import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../models/comment_model.dart';
import '../../models/reel_model.dart';
import '../../models/notification_model.dart';
import '../../config/user_config.dart';

class ReelsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _reelsCollection => _firestore.collection('reels');
  CollectionReference get _reelsDevCollection => _firestore.collection('reels-dev');
  CollectionReference get _commentsCollection => _firestore.collection('reels_comments');
  CollectionReference get _notificationsCollection => _firestore.collection('notifications');

  // Cache en memoria
  static final Map<String, List<ReelModel>> _memoryCache = {};
  static DateTime _lastMemoryCacheUpdate = DateTime.now();
  static const Duration _memoryCacheDuration = Duration(minutes: 10);

  // Cache persistente
  static const String _persistentCacheKey = 'cached_reels';

  // Obtener reels aprobados con caché
  Future<List<ReelModel>> getReels({
    String? groupId,
    int limit = 10,
    DocumentSnapshot? lastDocument,
    bool useCache = true,
  }) async {
    // Intentar cargar desde caché en memoria primero
    if (useCache && _isMemoryCacheValid(groupId)) {
      final cached = _memoryCache[groupId ?? 'all'];
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
    }

    // Intentar cargar desde caché persistente
    if (useCache) {
      final persisted = await _loadFromPersistentCache();
      if (persisted.isNotEmpty) {
        _memoryCache[groupId ?? 'all'] = persisted;
        _lastMemoryCacheUpdate = DateTime.now();
        return persisted;
      }
    }

    try {
      Query query = _reelsCollection
          .where('status', isEqualTo: 'approved')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (groupId != null && groupId.isNotEmpty) {
        query = query.where('groupId', isEqualTo: groupId);
      }

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final QuerySnapshot snapshot = await query.get();

      final reels = snapshot.docs.map((doc) {
        return ReelModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();

      // Guardar en caché en memoria
      _memoryCache[groupId ?? 'all'] = reels;
      _lastMemoryCacheUpdate = DateTime.now();

      // Guardar en caché persistente
      await _saveToPersistentCache(reels);

      return reels;
    } catch (e) {
      print('Error getting reels: $e');
      return [];
    }
  }

  bool _isMemoryCacheValid(String? groupId) {
    return DateTime.now().difference(_lastMemoryCacheUpdate) < _memoryCacheDuration &&
        _memoryCache.containsKey(groupId ?? 'all');
  }

  Future<void> _saveToPersistentCache(List<ReelModel> reels) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reelsJson = reels.map((r) => jsonEncode({
        'id': r.id,
        'videoUrl': r.videoUrl,
        'thumbnailUrl': r.thumbnailUrl,
        'title': r.title,
        'description': r.description,
        'userId': r.userId,
        'userName': r.userName,
        'userAvatar': r.userAvatar,
        'groupId': r.groupId,
        'likes': r.likes,
        'comments': r.comments,
        'views': r.views,
      })).toList();
      await prefs.setStringList(_persistentCacheKey, reelsJson);
    } catch (e) {
      print('Error saving to cache: $e');
    }
  }

  Future<List<ReelModel>> _loadFromPersistentCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reelsJson = prefs.getStringList(_persistentCacheKey);
      if (reelsJson == null) return [];

      return reelsJson.map((json) {
        final data = jsonDecode(json) as Map<String, dynamic>;
        return ReelModel(
          id: data['id'],
          videoUrl: data['videoUrl'],
          thumbnailUrl: data['thumbnailUrl'] ?? '',
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          userId: data['userId'] ?? '',
          userName: data['userName'] ?? '',
          userAvatar: data['userAvatar'] ?? '',
          groupId: data['groupId'] ?? 'cultura',
          likes: data['likes'] ?? 0,
          comments: data['comments'] ?? 0,
          views: data['views'] ?? 0,
          createdAt: Timestamp.now(),
        );
      }).toList();
    } catch (e) {
      print('Error loading from cache: $e');
      return [];
    }
  }

  // Obtener reels pendientes (para control de contenido)
  Future<List<ReelModel>> getPendingReels() async {
    try {
      final snapshot = await _reelsDevCollection
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return ReelModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print('Error getting pending reels: $e');
      return [];
    }
  }

  // Subir un nuevo reel (se guarda en reels-dev como pendiente)
  Future<String?> uploadReel(ReelModel reel) async {
    try {
      final docRef = await _reelsDevCollection.add(reel.toMap());

      // Limpiar caché
      _memoryCache.clear();
      await _saveToPersistentCache([]);

      // Crear notificación para moderadores
      await _createModeratorNotification(
        title: 'Nuevo reel pendiente',
        message: '${reel.userName} ha subido un nuevo reel: "${reel.title}"',
        type: 'pending_approval',
        relatedId: docRef.id,
      );

      return docRef.id;
    } catch (e) {
      print('Error uploading reel: $e');
      return null;
    }
  }

  // Aprobar reel
  Future<bool> approveReel(String reelId, {String? approvedBy}) async {
    try {
      // Obtener el reel de reels-dev
      final devDoc = await _reelsDevCollection.doc(reelId).get();
      if (!devDoc.exists) return false;

      final reelData = devDoc.data() as Map<String, dynamic>;
      reelData['status'] = 'approved';
      reelData['approvedAt'] = Timestamp.now();
      reelData['approvedBy'] = approvedBy ?? UserConfig.currentUserId;

      // Mover a reels (público)
      await _reelsCollection.add(reelData);

      // Eliminar de reels-dev
      await _reelsDevCollection.doc(reelId).delete();

      // Limpiar caché
      _memoryCache.clear();
      await _saveToPersistentCache([]);

      // Notificar al creador
      await _createNotification(
        userId: reelData['userId'],
        title: 'Reel aprobado ✅',
        message: 'Tu reel "${reelData['title']}" ha sido aprobado y ya está visible.',
        type: 'approval',
        relatedId: reelId,
      );

      return true;
    } catch (e) {
      print('Error approving reel: $e');
      return false;
    }
  }

  // Rechazar reel
  Future<bool> rejectReel(String reelId, String reason) async {
    try {
      final devDoc = await _reelsDevCollection.doc(reelId).get();
      if (!devDoc.exists) return false;

      final reelData = devDoc.data() as Map<String, dynamic>;

      // Notificar al creador
      await _createNotification(
        userId: reelData['userId'],
        title: 'Reel rechazado ❌',
        message: 'Tu reel "${reelData['title']}" ha sido rechazado. Motivo: $reason',
        type: 'rejection',
        relatedId: reelId,
      );

      // Eliminar de reels-dev
      await _reelsDevCollection.doc(reelId).delete();

      return true;
    } catch (e) {
      print('Error rejecting reel: $e');
      return false;
    }
  }

  // Agregar comentario
  Future<void> addComment(String reelId, String text) async {
    final comment = CommentModel(
      reelId: reelId,
      userId: UserConfig.currentUserId,
      userName: UserConfig.currentUserName,
      userAvatar: UserConfig.currentUserAvatar,
      text: text,
      createdAt: Timestamp.now(),
    );

    await _commentsCollection.add(comment.toMap());

    // Incrementar contador de comentarios en el reel
    await _reelsCollection.doc(reelId).update({
      'comments': FieldValue.increment(1),
    });

    // Notificar al creador del reel
    final reelDoc = await _reelsCollection.doc(reelId).get();
    if (reelDoc.exists) {
      final reelData = reelDoc.data() as Map<String, dynamic>;
      if (reelData['userId'] != UserConfig.currentUserId) {
        await _createNotification(
          userId: reelData['userId'],
          title: 'Nuevo comentario 💬',
          message: '${UserConfig.currentUserName} comentó en tu reel: "$text"',
          type: 'comment',
          relatedId: reelId,
        );
      }
    }
  }

  // Obtener comentarios de un reel
  Stream<List<CommentModel>> getComments(String reelId) {
    return _commentsCollection
        .where('reelId', isEqualTo: reelId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CommentModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Dar like a un reel
  Future<void> likeReel(String reelId) async {
    final userId = UserConfig.currentUserId;
    final reelRef = _reelsCollection.doc(reelId);

    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(reelRef);
        if (!snapshot.exists) return;

        final data = snapshot.data() as Map<String, dynamic>;
        final likedBy = List<String>.from(data['likedBy'] ?? []);

        if (likedBy.contains(userId)) {
          transaction.update(reelRef, {
            'likes': FieldValue.increment(-1),
            'likedBy': FieldValue.arrayRemove([userId]),
          });
        } else {
          transaction.update(reelRef, {
            'likes': FieldValue.increment(1),
            'likedBy': FieldValue.arrayUnion([userId]),
          });

          // Notificar al creador
          if (data['userId'] != userId) {
            await _createNotification(
              userId: data['userId'],
              title: 'Nuevo like ❤️',
              message: '${UserConfig.currentUserName} le gustó tu reel "${data['title']}"',
              type: 'like',
              relatedId: reelId,
            );
          }
        }
      });
    } catch (e) {
      print('Error liking reel: $e');
    }
  }

  // Verificar like
  Future<bool> isLiked(String reelId) async {
    final userId = UserConfig.currentUserId;
    final doc = await _reelsCollection.doc(reelId).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final likedBy = List<String>.from(data['likedBy'] ?? []);
      return likedBy.contains(userId);
    }
    return false;
  }

  // Incrementar vistas
  Future<void> incrementViews(String reelId) async {
    try {
      await _reelsCollection.doc(reelId).update({
        'views': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error incrementing views: $e');
    }
  }

  // Obtener notificaciones del usuario
  Stream<List<NotificationModel>> getNotifications() {
    return _notificationsCollection
        .where('userId', isEqualTo: UserConfig.currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return NotificationModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Marcar notificación como leída
  Future<void> markNotificationAsRead(String notificationId) async {
    await _notificationsCollection.doc(notificationId).update({
      'isRead': true,
    });
  }

  // Crear notificación individual
  Future<void> _createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? relatedId,
  }) async {
    final notification = NotificationModel(
      userId: userId,
      title: title,
      message: message,
      type: type,
      relatedId: relatedId,
      createdAt: Timestamp.now(),
    );
    await _notificationsCollection.add(notification.toMap());
  }

  // Crear notificación para moderadores
  Future<void> _createModeratorNotification({
    required String title,
    required String message,
    required String type,
    String? relatedId,
  }) async {
    // Por ahora notificamos a los admins hardcodeados
    final moderatorIds = ['temp_user_001']; // ID del admin

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

  List<Map<String, dynamic>> getGroups() {
    return [
      {'id': 'cultura', 'name': '🎉 Cultura', 'color': 0xFF005DB9},
      {'id': 'anuncios', 'name': '📢 Anuncios', 'color': 0xFF009BDF},
      {'id': 'capacitacion', 'name': '📚 Capacitación', 'color': 0xFFF32836},
    ];
  }
}