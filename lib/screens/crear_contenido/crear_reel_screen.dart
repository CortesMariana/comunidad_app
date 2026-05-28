import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/reel_model.dart';
import '../../services/reels/reels_service.dart';
import '../../config/user_config.dart';

class CrearReelScreen extends StatefulWidget {
  const CrearReelScreen({super.key});

  @override
  State<CrearReelScreen> createState() => _CrearReelScreenState();
}

class _CrearReelScreenState extends State<CrearReelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedGroup = 'cultura';
  File? _selectedVideo;
  File? _selectedThumbnail;
  bool _isUploading = false;
  double _uploadProgress = 0;

  // Para previsualización de video
  VideoPlayerController? _videoPreviewController;
  bool _isVideoInitialized = false;

  final ReelsService _reelsService = ReelsService();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.gallery);

    if (video != null) {
      // Limpiar controller anterior
      if (_videoPreviewController != null) {
        _videoPreviewController!.dispose();
      }

      setState(() {
        _selectedVideo = File(video.path);
        _isVideoInitialized = false;
      });

      // Inicializar previsualización
      _videoPreviewController = VideoPlayerController.file(File(video.path));
      await _videoPreviewController!.initialize();
      setState(() {
        _isVideoInitialized = true;
      });
      _videoPreviewController!.play();
    }
  }

  Future<void> _pickThumbnail() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedThumbnail = File(image.path);
      });
    }
  }

  Future<void> _uploadReel() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVideo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un video')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

    try {
      // Subir video
      final videoFileName = 'reels/${DateTime.now().millisecondsSinceEpoch}_video.mp4';
      final videoRef = _storage.ref().child(videoFileName);

      final videoUploadTask = videoRef.putFile(_selectedVideo!);
      videoUploadTask.snapshotEvents.listen((event) {
        setState(() {
          _uploadProgress = event.bytesTransferred / event.totalBytes;
        });
      });

      await videoUploadTask;
      final videoUrl = await videoRef.getDownloadURL();

      // Subir thumbnail si existe
      String thumbnailUrl = '';
      if (_selectedThumbnail != null) {
        final thumbFileName = 'reels/thumbnails/${DateTime.now().millisecondsSinceEpoch}_thumb.jpg';
        final thumbRef = _storage.ref().child(thumbFileName);
        await thumbRef.putFile(_selectedThumbnail!);
        thumbnailUrl = await thumbRef.getDownloadURL();
      }

      // Crear reel en Firestore (se guarda en reels-dev como pendiente)
      final newReel = ReelModel(
        videoUrl: videoUrl,
        thumbnailUrl: thumbnailUrl,
        title: _titleController.text,
        description: _descriptionController.text,
        userId: UserConfig.currentUserId,
        userName: UserConfig.currentUserName,
        userAvatar: UserConfig.currentUserAvatar,
        groupId: _selectedGroup,
        createdAt: Timestamp.now(),
        status: 'pending', // Pendiente de aprobación
      );

      final reelId = await _reelsService.uploadReel(newReel);

      if (reelId != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Reel subido exitosamente! Pasará por revisión antes de ser publicado.'),
            backgroundColor: Color(0xFF005DB9),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _videoPreviewController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groups = _reelsService.getGroups();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Reel'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF005DB9),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selección de video con previsualización
              GestureDetector(
                onTap: _pickVideo,
                child: Container(
                  height: 400,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[800]!),
                  ),
                  child: _selectedVideo != null && _isVideoInitialized
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: VideoPlayer(_videoPreviewController!),
                  )
                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.video_library, size: 50, color: Colors.grey[600]),
                      const SizedBox(height: 8),
                      Text(
                        'Seleccionar video',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'MP4, MOV hasta 100MB',
                        style: TextStyle(color: Colors.grey[500], fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Miniatura
              GestureDetector(
                onTap: _pickThumbnail,
                child: Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: _selectedThumbnail != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      _selectedThumbnail!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  )
                      : Center(
                    child: Text(
                      'Seleccionar miniatura (opcional)',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Título
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título del reel',
                  hintText: 'Ej: ¡Gran anuncio!',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa un título';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Descripción
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Cuéntales de qué trata...',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),

              // Categoría
              DropdownButtonFormField<String>(
                value: _selectedGroup,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                ),
                items: groups.map<DropdownMenuItem<String>>((group) {
                  return DropdownMenuItem<String>(
                    value: group['id'] as String,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Color(group['color'] as int),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(group['name'] as String),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGroup = value!;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Mensaje de aprobación
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Los reels pasan por un proceso de revisión antes de ser publicados.',
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.orange[700]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Botón de subir
              if (_isUploading)
                Column(
                  children: [
                    LinearProgressIndicator(value: _uploadProgress),
                    const SizedBox(height: 8),
                    Text('Subiendo: ${(_uploadProgress * 100).toStringAsFixed(0)}%'),
                  ],
                )
              else
                ElevatedButton(
                  onPressed: _uploadReel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF32836),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text(
                    'SUBIR REEL',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}