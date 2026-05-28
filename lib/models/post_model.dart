import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum PostStatus {
  pending('pendiente', Colors.orange),
  approved('aprobado', Colors.green),
  rejected('rechazado', Color(0xFFF32836));

  final String label;
  final Color color;

  const PostStatus(this.label, this.color);
}

class PostModel {
  String? id;
  String userId;
  String userName;
  String userAvatar;
  String content;
  String? imageUrl;
  List<String> imageUrls;
  int likes;
  int comments;
  int shares;
  List<String> likedBy;
  String status; // pending, approved, rejected
  String? rejectionReason;
  Timestamp? approvedAt;
  String? approvedBy;
  Timestamp createdAt;
  bool isScheduled;
  DateTime? scheduledDate;
  String? groupId; // 'anuncios', 'capacitacion', 'cultura'

  PostModel({
    this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.content,
    this.imageUrl,
    this.imageUrls = const [],
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.likedBy = const [],
    this.status = 'pending',
    this.rejectionReason,
    this.approvedAt,
    this.approvedBy,
    required this.createdAt,
    this.isScheduled = false,
    this.scheduledDate,
    this.groupId = 'anuncios',
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'content': content,
      'imageUrl': imageUrl,
      'imageUrls': imageUrls,
      'likes': likes,
      'comments': comments,
      'shares': shares,
      'likedBy': likedBy,
      'status': status,
      'rejectionReason': rejectionReason,
      'approvedAt': approvedAt,
      'approvedBy': approvedBy,
      'createdAt': createdAt,
      'isScheduled': isScheduled,
      'scheduledDate': scheduledDate,
      'groupId': groupId,
    };
  }

  factory PostModel.fromMap(String id, Map<String, dynamic> map) {
    return PostModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userAvatar: map['userAvatar'] ?? '',
      content: map['content'] ?? '',
      imageUrl: map['imageUrl'],
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      likes: map['likes'] ?? 0,
      comments: map['comments'] ?? 0,
      shares: map['shares'] ?? 0,
      likedBy: List<String>.from(map['likedBy'] ?? []),
      status: map['status'] ?? 'pending',
      rejectionReason: map['rejectionReason'],
      approvedAt: map['approvedAt'],
      approvedBy: map['approvedBy'],
      createdAt: map['createdAt'] ?? Timestamp.now(),
      isScheduled: map['isScheduled'] ?? false,
      scheduledDate: map['scheduledDate']?.toDate(),
      groupId: map['groupId'] ?? 'anuncios',
    );
  }
}

// Tipos de reacción para publicaciones
enum ReactionType {
  like('like', '❤️'),
  love('love', '😍'),
  laugh('laugh', '😂'),
  sad('sad', '😢'),
  angry('angry', '😡');

  final String value;
  final String emoji;

  const ReactionType(this.value, this.emoji);
}

class PostReaction {
  String userId;
  String postId;
  String reactionType;
  Timestamp createdAt;

  PostReaction({
    required this.userId,
    required this.postId,
    required this.reactionType,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'postId': postId,
      'reactionType': reactionType,
      'createdAt': createdAt,
    };
  }
}