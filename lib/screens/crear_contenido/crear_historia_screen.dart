import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/user_config.dart';

class CrearHistoriaScreen extends StatefulWidget {
  const CrearHistoriaScreen({super.key});

  @override
  State<CrearHistoriaScreen> createState() => _CrearHistoriaScreenState();
}

class _CrearHistoriaScreenState extends State<CrearHistoriaScreen> {
  File? _selectedMedia;
  String _mediaType = 'image'; // 'image' or 'video'
  String _text = '';
  bool _isUploading = false;
  double _uploadProgress = 0;

  VideoPlayerController? _videoPreviewController;

  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _cleanupVideo();
      setState(() {
        _selectedMedia = File(image.path);
        _mediaType = 'image';
      });
    }
  }

  Future<void> _pickVideo() async {
    final video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      _cleanupVideo();
      _videoPreviewController = VideoPlayerController.file(File(video.path));
      await _videoPreviewController!.initialize();
      setState(() {
        _selectedMedia = File(video.path);
        _mediaType = 'video';
      });
      _videoPreviewController!.play();
    }
  }

  void _cleanupVideo() {
    if (_videoPreviewController != null) {
      _videoPreviewController!.dispose();
      _videoPreviewController = null;
    }
  }

  Future<void> _uploadHistoria() async {
    if (_selectedMedia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una imagen o video')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

    try {
      String mediaUrl;
      final fileName = 'historias/${DateTime.now().millisecondsSinceEpoch}_${_mediaType == 'image' ? 'image.jpg' : 'video.mp4'}';
      final ref = _storage.ref().child(fileName);

      final uploadTask = ref.putFile(_selectedMedia!);
      uploadTask.snapshotEvents.listen((event) {
        setState(() {
          _uploadProgress = event.bytesTransferred / event.totalBytes;
        });
      });

      await uploadTask;
      mediaUrl = await ref.getDownloadURL();

      // La historia expira en 24 horas
      final expiresAt = Timestamp.fromDate(DateTime.now().add(const Duration(hours: 24)));

      final historiaData = {
        'userId': UserConfig.currentUserId,
        'userName': UserConfig.currentUserName,
        'userAvatar': UserConfig.currentUserAvatar,
        'mediaUrl': mediaUrl,
        'type': _mediaType,
        'text': _text,
        'createdAt': Timestamp.now(),
        'expiresAt': expiresAt,
        'views': 0,
        'viewedBy': [],
      };

      await _firestore.collection('historias').add(historiaData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Historia publicada. Estará visible por 24 horas.'),
            backgroundColor: Color(0xFF009BDF),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  void dispose() {
    _cleanupVideo();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crear Historia', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF009BDF),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selector de tipo
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_camera),
                    label: const Text('Imagen'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF009BDF),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickVideo,
                    icon: const Icon(Icons.videocam),
                    label: const Text('Video'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF009BDF),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Previsualización
            Container(
              height: 400,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF005DB9), Color(0xFF009BDF)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: _selectedMedia != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: _mediaType == 'image'
                    ? Image.file(_selectedMedia!, fit: BoxFit.cover)
                    : _videoPreviewController != null && _videoPreviewController!.value.isInitialized
                    ? VideoPlayer(_videoPreviewController!)
                    : const Center(child: CircularProgressIndicator()),
              )
                  : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate, size: 60, color: Colors.white54),
                    const SizedBox(height: 16),
                    Text(
                      'Selecciona una imagen o video',
                      style: GoogleFonts.poppins(color: Colors.white70),
                    ),
                    Text(
                      '(La historia estará visible por 24 horas)',
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Texto opcional
            TextField(
              decoration: const InputDecoration(
                labelText: 'Texto (opcional)',
                hintText: 'Acompaña tu historia con un mensaje...',
              ),
              maxLines: 2,
              onChanged: (value) => _text = value,
            ),
            const SizedBox(height: 24),

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
                onPressed: _uploadHistoria,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF009BDF),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text(
                  'COMPARTIR HISTORIA',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}