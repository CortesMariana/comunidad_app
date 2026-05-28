import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/posts/posts_service.dart';
import '../../models/post_model.dart';
import '../../config/user_config.dart';

class CrearPublicacionScreen extends StatefulWidget {
  const CrearPublicacionScreen({super.key});

  @override
  State<CrearPublicacionScreen> createState() => _CrearPublicacionScreenState();
}

class _CrearPublicacionScreenState extends State<CrearPublicacionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();

  File? _selectedImage;
  bool _isScheduled = false;
  DateTime _scheduledDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _scheduledTime = TimeOfDay.now();
  bool _isUploading = false;
  String _selectedGroup = 'anuncios';

  final PostsService _postsService = PostsService();
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _selectScheduleDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _scheduledDate,
    );
    if (date != null) {
      setState(() {
        _scheduledDate = date;
      });
    }
  }

  Future<void> _selectScheduleTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _scheduledTime,
    );
    if (time != null) {
      setState(() {
        _scheduledTime = time;
      });
    }
  }

  Future<void> _createPost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploading = true);

    String? imageUrl;
    if (_selectedImage != null) {
      imageUrl = await _postsService.uploadImage(_selectedImage!);
    }

    final scheduledDateTime = DateTime(
      _scheduledDate.year,
      _scheduledDate.month,
      _scheduledDate.day,
      _scheduledTime.hour,
      _scheduledTime.minute,
    );

    final post = PostModel(
      userId: UserConfig.currentUserId,
      userName: UserConfig.currentUserName,
      userAvatar: UserConfig.currentUserAvatar,
      content: _contentController.text,
      imageUrl: imageUrl,
      createdAt: Timestamp.now(),
      isScheduled: _isScheduled,
      scheduledDate: _isScheduled ? scheduledDateTime : null,
      groupId: _selectedGroup,
    );

    final postId = await _postsService.createPost(post);

    setState(() => _isUploading = false);

    if (postId != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isScheduled
              ? 'Publicación programada para ${scheduledDateTime.day}/${scheduledDateTime.month} a las ${scheduledDateTime.hour}:${scheduledDateTime.minute.toString().padLeft(2, '0')}'
              : 'Publicación creada. Pasará por revisión.'),
          backgroundColor: const Color(0xFF005DB9),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crear Publicación', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
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
              // Categoría
              DropdownButtonFormField<String>(
                value: _selectedGroup,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: const [
                  DropdownMenuItem(value: 'anuncios', child: Text('📢 Anuncios')),
                  DropdownMenuItem(value: 'capacitacion', child: Text('📚 Capacitación')),
                  DropdownMenuItem(value: 'cultura', child: Text('🎉 Cultura')),
                ],
                onChanged: (value) => setState(() => _selectedGroup = value!),
              ),
              const SizedBox(height: 16),

              // Contenido
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: '¿Qué estás pensando?',
                  hintText: 'Comparte algo con tu comunidad...',
                ),
                maxLines: 5,
                validator: (v) => v == null || v.isEmpty ? 'Escribe algo' : null,
              ),
              const SizedBox(height: 16),

              // Imagen
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(_selectedImage!, fit: BoxFit.cover),
                  )
                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey[600]),
                      const SizedBox(height: 8),
                      Text('Agregar imagen', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Programar publicación
              Card(
                child: SwitchListTile(
                  title: const Text('Programar publicación'),
                  subtitle: const Text('La publicación se guardará como borrador hasta la fecha seleccionada'),
                  value: _isScheduled,
                  onChanged: (value) => setState(() => _isScheduled = value),
                  activeColor: const Color(0xFF005DB9),
                ),
              ),

              if (_isScheduled) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _selectScheduleDate,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.calendar_today, color: Color(0xFF005DB9)),
                              const SizedBox(height: 4),
                              Text(
                                '${_scheduledDate.day}/${_scheduledDate.month}/${_scheduledDate.year}',
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: _selectScheduleTime,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.access_time, color: Color(0xFF005DB9)),
                              const SizedBox(height: 4),
                              Text(
                                '${_scheduledTime.hour}:${_scheduledTime.minute.toString().padLeft(2, '0')}',
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),

              if (_isUploading)
                const LinearProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _createPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF005DB9),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(
                    _isScheduled ? 'PROGRAMAR PUBLICACIÓN' : 'PUBLICAR',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }
}