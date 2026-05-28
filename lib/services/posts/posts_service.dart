import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../models/post_model.dart';
import '../../models/notification_model.dart';
import '../../config/user_config.dart';

class PostsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference get _postsCollection => _firestore.collection('posts');
  CollectionReference get _postsDevCollection => _firestore.collection('posts-dev');
  CollectionReference get _postsReactionsCollection => _firestore.collection('posts_reactions');
  CollectionReference get _notificationsCollection => _firestore.collection('notifications');

  // Cache en memoria
  static final List<PostModel> _memoryCache = [];
  static DateTime _lastCacheUpdate = DateTime.now();
  static const Duration _cacheDuration = Duration(minutes: 10);

  // Obtener publicaciones aprobadas (para Home)
  Future<List<PostModel>> getApprovedPosts({
    int limit = 10,
    DocumentSnapshot? lastDocument,
    bool useCache = true,
  }) async {
    // Verificar caché
    if (useCache && _isCacheValid() && _memoryCache.isNotEmpty) {
      return _memoryCache;
    }

    try {
      Query query = _postsCollection
          .where('status', isEqualTo: 'approved')
          .where('isScheduled', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final QuerySnapshot snapshot = await query.get();

      final posts = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return PostModel.fromMap(doc.id, data);
      }).toList();

      // Actualizar caché
      _memoryCache.clear();
      _memoryCache.addAll(posts);
      _lastCacheUpdate = DateTime.now();

      return posts;
    } catch (e) {
      print('Error getting posts: $e');
      return [];
    }
  }

  // Obtener publicaciones programadas (para fecha específica)
  Future<List<PostModel>> getScheduledPostsForDate(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _postsCollection
          .where('status', isEqualTo: 'approved')
          .where('isScheduled', isEqualTo: true)
          .where('scheduledDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('scheduledDate', isLessThan: Timestamp.fromDate(endOfDay))
          .orderBy('scheduledDate', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return PostModel.fromMap(doc.id, data);
      }).toList();
    } catch (e) {
      print('Error getting scheduled posts: $e');
      return [];
    }
  }

  // Obtener publicaciones pendientes (para Control de Contenido)
  Stream<List<PostModel>> getPendingPosts() {
    return _postsDevCollection
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return PostModel.fromMap(doc.id, data);
      }).toList();
    });
  }

  // Obtener publicaciones programadas
  Stream<List<PostModel>> getScheduledPosts() {
    final now = Timestamp.now();
    return _postsDevCollection
        .where('isScheduled', isEqualTo: true)
        .where('scheduledDate', isGreaterThan: now)
        .orderBy('scheduledDate', descending: false)  // ascending = false no existe, usar descending false
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return PostModel.fromMap(doc.id, data);
      }).toList();
    });
  }

  // Crear una nueva publicación (se guarda en posts-dev como pendiente)
  Future<String?> createPost(PostModel post) async {
    try {
      final docRef = await _postsDevCollection.add(post.toMap());

      // Limpiar caché
      _memoryCache.clear();

      // Crear notificación para moderadores
      await _createModeratorNotification(
        title: 'Nueva publicación pendiente',
        message: '${post.userName} ha creado una nueva publicación',
        type: 'pending_approval',
        relatedId: docRef.id,
      );

      return docRef.id;
    } catch (e) {
      print('Error creating post: $e');
      return null;
    }
  }

  // Subir imagen a Storage
  Future<String?> uploadImage(File imageFile) async {
    try {
      final fileName = 'posts/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child(fileName);
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Aprobar publicación
  Future<bool> approvePost(String postId, {String? approvedBy}) async {
    try {
      final devDoc = await _postsDevCollection.doc(postId).get();
      if (!devDoc.exists) return false;

      final postData = devDoc.data() as Map<String, dynamic>;
      postData['status'] = 'approved';
      postData['approvedAt'] = Timestamp.now();
      postData['approvedBy'] = approvedBy ?? UserConfig.currentUserId;

      // Mover a posts (público)
      await _postsCollection.add(postData);

      // Eliminar de posts-dev
      await _postsDevCollection.doc(postId).delete();

      // Limpiar caché
      _memoryCache.clear();

      // Notificar al creador
      await _createNotification(
        userId: postData['userId'],
        title: 'Publicación aprobada ✅',
        message: 'Tu publicación ha sido aprobada y ya está visible.',
        type: 'approval',
        relatedId: postId,
      );

      return true;
    } catch (e) {
      print('Error approving post: $e');
      return false;
    }
  }

  // Rechazar publicación
  Future<bool> rejectPost(String postId, String reason) async {
    try {
      final devDoc = await _postsDevCollection.doc(postId).get();
      if (!devDoc.exists) return false;

      final postData = devDoc.data() as Map<String, dynamic>;

      // Notificar al creador
      await _createNotification(
        userId: postData['userId'],
        title: 'Publicación rechazada ❌',
        message: 'Tu publicación ha sido rechazada. Motivo: $reason',
        type: 'rejection',
        relatedId: postId,
      );

      // Eliminar de posts-dev
      await _postsDevCollection.doc(postId).delete();

      return true;
    } catch (e) {
      print('Error rejecting post: $e');
      return false;
    }
  }

  // Dar like a una publicación
  Future<void> likePost(String postId) async {
    final userId = UserConfig.currentUserId;
    final postRef = _postsCollection.doc(postId);

    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(postRef);
        if (!snapshot.exists) return;

        final data = snapshot.data() as Map<String, dynamic>;
        final likedBy = List<String>.from(data['likedBy'] ?? []);

        if (likedBy.contains(userId)) {
          transaction.update(postRef, {
            'likes': FieldValue.increment(-1),
            'likedBy': FieldValue.arrayRemove([userId]),
          });
        } else {
          transaction.update(postRef, {
            'likes': FieldValue.increment(1),
            'likedBy': FieldValue.arrayUnion([userId]),
          });

          if (data['userId'] != userId) {
            await _createNotification(
              userId: data['userId'],
              title: 'Nuevo like ❤️',
              message: '${UserConfig.currentUserName} le gustó tu publicación',
              type: 'like',
              relatedId: postId,
            );
          }
        }
      });
    } catch (e) {
      print('Error liking post: $e');
    }
  }

  // Verificar like
  Future<bool> isLiked(String postId) async {
    final userId = UserConfig.currentUserId;
    final doc = await _postsCollection.doc(postId).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final likedBy = List<String>.from(data['likedBy'] ?? []);
      return likedBy.contains(userId);
    }
    return false;
  }

  // Agregar comentario
  Future<void> addComment(String postId, String text) async {
    final comment = {
      'postId': postId,
      'userId': UserConfig.currentUserId,
      'userName': UserConfig.currentUserName,
      'userAvatar': UserConfig.currentUserAvatar,
      'text': text,
      'likes': 0,
      'createdAt': Timestamp.now(),
    };

    await _firestore.collection('posts_comments').add(comment);

    await _postsCollection.doc(postId).update({
      'comments': FieldValue.increment(1),
    });
  }

  // Obtener comentarios de una publicación
  Stream<List<Map<String, dynamic>>> getComments(String postId) {
    return _firestore
        .collection('posts_comments')
        .where('postId', isEqualTo: postId)
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

  // Reacciones con emojis
  Future<void> addReaction(String postId, ReactionType reaction) async {
    final userId = UserConfig.currentUserId;
    final reactionRef = _postsReactionsCollection.doc('$userId-$postId');

    final existing = await reactionRef.get();

    if (existing.exists) {
      await reactionRef.update({
        'reactionType': reaction.value,
        'updatedAt': Timestamp.now(),
      });
    } else {
      await reactionRef.set({
        'userId': userId,
        'postId': postId,
        'reactionType': reaction.value,
        'createdAt': Timestamp.now(),
      });
    }
  }

  // Obtener reacción del usuario
  Future<String?> getUserReaction(String postId) async {
    final userId = UserConfig.currentUserId;
    final doc = await _postsReactionsCollection.doc('$userId-$postId').get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      return data['reactionType'];
    }
    return null;
  }

  bool _isCacheValid() {
    return DateTime.now().difference(_lastCacheUpdate) < _cacheDuration;
  }

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