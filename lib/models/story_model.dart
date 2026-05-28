import 'package:cloud_firestore/cloud_firestore.dart';

class StoryModel {
  String? id;
  String userId;
  String userName;
  String userAvatar;
  String mediaUrl;
  String type; // 'image' or 'video'
  String text;
  String status; // 'pending', 'approved', 'rejected'
  Timestamp createdAt;
  Timestamp expiresAt;
  int views;
  List<String> viewedBy;
  String? rejectionReason;
  Timestamp? approvedAt;
  String? approvedBy;

  StoryModel({
    this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.mediaUrl,
    required this.type,
    required this.text,
    this.status = 'pending',
    required this.createdAt,
    required this.expiresAt,
    this.views = 0,
    this.viewedBy = const [],
    this.rejectionReason,
    this.approvedAt,
    this.approvedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'mediaUrl': mediaUrl,
      'type': type,
      'text': text,
      'status': status,
      'createdAt': createdAt,
      'expiresAt': expiresAt,
      'views': views,
      'viewedBy': viewedBy,
      'rejectionReason': rejectionReason,
      'approvedAt': approvedAt,
      'approvedBy': approvedBy,
    };
  }

  factory StoryModel.fromMap(String id, Map<String, dynamic> map) {
    return StoryModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userAvatar: map['userAvatar'] ?? '',
      mediaUrl: map['mediaUrl'] ?? '',
      type: map['type'] ?? 'image',
      text: map['text'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: map['createdAt'] ?? Timestamp.now(),
      expiresAt: map['expiresAt'] ?? Timestamp.now(),
      views: map['views'] ?? 0,
      viewedBy: List<String>.from(map['viewedBy'] ?? []),
      rejectionReason: map['rejectionReason'],
      approvedAt: map['approvedAt'],
      approvedBy: map['approvedBy'],
    );
  }
}