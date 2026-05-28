import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum ReelStatus {
  pending('pendiente', Colors.orange),
  approved('aprobado', Colors.green),
  rejected('rechazado', Color(0xFFF32836));

  final String label;
  final Color color;

  const ReelStatus(this.label, this.color);
}

class ReelModel {
  String? id;
  String videoUrl;
  String thumbnailUrl;
  String title;
  String description;
  String userId;
  String userName;
  String userAvatar;
  String groupId;
  int likes;
  int comments;
  int shares;
  int views;
  List<String> likedBy;
  Timestamp createdAt;
  bool isActive;
  String status; // 'pending', 'approved', 'rejected'
  String? rejectionReason;
  Timestamp? approvedAt;
  String? approvedBy;

  ReelModel({
    this.id,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.title,
    required this.description,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.groupId,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.views = 0,
    this.likedBy = const [],
    required this.createdAt,
    this.isActive = true,
    this.status = 'pending',
    this.rejectionReason,
    this.approvedAt,
    this.approvedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'title': title,
      'description': description,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'groupId': groupId,
      'likes': likes,
      'comments': comments,
      'shares': shares,
      'views': views,
      'likedBy': likedBy,
      'createdAt': createdAt,
      'isActive': isActive,
      'status': status,
      'rejectionReason': rejectionReason,
      'approvedAt': approvedAt,
      'approvedBy': approvedBy,
    };
  }

  factory ReelModel.fromMap(String id, Map<String, dynamic> map) {
    return ReelModel(
      id: id,
      videoUrl: map['videoUrl'] ?? '',
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userAvatar: map['userAvatar'] ?? '',
      groupId: map['groupId'] ?? 'cultura',
      likes: map['likes'] ?? 0,
      comments: map['comments'] ?? 0,
      shares: map['shares'] ?? 0,
      views: map['views'] ?? 0,
      likedBy: List<String>.from(map['likedBy'] ?? []),
      createdAt: map['createdAt'] ?? Timestamp.now(),
      isActive: map['isActive'] ?? true,
      status: map['status'] ?? 'pending',
      rejectionReason: map['rejectionReason'],
      approvedAt: map['approvedAt'],
      approvedBy: map['approvedBy'],
    );
  }
}