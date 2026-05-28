import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  String? id;
  String userId;
  String title;
  String message;
  String type; // 'like', 'comment', 'approval', 'rejection'
  String? relatedId; // reelId, commentId, etc.
  bool isRead;
  Timestamp createdAt;

  NotificationModel({
    this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.relatedId,
    this.isRead = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'relatedId': relatedId,
      'isRead': isRead,
      'createdAt': createdAt,
    };
  }

  factory NotificationModel.fromMap(String id, Map<String, dynamic> map) {
    return NotificationModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: map['type'] ?? '',
      relatedId: map['relatedId'],
      isRead: map['isRead'] ?? false,
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }
}