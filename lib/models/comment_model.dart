import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  String? id;
  String reelId;
  String userId;
  String userName;
  String userAvatar;
  String text;
  int likes;
  List<String> likedBy;
  Timestamp createdAt;

  CommentModel({
    this.id,
    required this.reelId,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.text,
    this.likes = 0,
    this.likedBy = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'reelId': reelId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'text': text,
      'likes': likes,
      'likedBy': likedBy,
      'createdAt': createdAt,
    };
  }

  factory CommentModel.fromMap(String id, Map<String, dynamic> map) {
    return CommentModel(
      id: id,
      reelId: map['reelId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userAvatar: map['userAvatar'] ?? '',
      text: map['text'] ?? '',
      likes: map['likes'] ?? 0,
      likedBy: List<String>.from(map['likedBy'] ?? []),
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }
}