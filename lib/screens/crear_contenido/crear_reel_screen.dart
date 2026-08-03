import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/reel_model.dart';
import '../../services/reels/reels_service.dart';
import '../../config/usuario_config.dart';

class CrearReelScreen extends StatefulWidget {
  const CrearReelScreen({super.key});

  @override
  State<CrearReelScreen> createState() => _CrearReelScreenState();
}

class _CrearReelScreenState extends State<CrearReelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final ReelsService _service = ReelsService();
  final ImagePicker _picker = ImagePicker();

  File? _videoFile;
  File? _miniaturaFile;
  VideoPlayerController? _previewCtrl;
  String _categoriaSeleccionada = 'cultura';
  bool _subiendo = false;
  double _progreso = 0;

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    _previewCtrl?.dispose();
    super.dispose();
  }

  Future<void> _seleccionarVideo() async {
    final video = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 3),
    );
    if (video == null) return;

    final archivo = File(video.path);
    final ctrl = VideoPlayerController.file(archivo);
    await ctrl.initialize();

    _previewCtrl?.dispose();
    setState(() {
      _videoFile = archivo;
      _previewCtrl = ctrl;
    });
    ctrl.play();
  }

  Future<void> _seleccionarMiniatura() async {
    final imagen = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (imagen == null) return;
    setState(() => _miniaturaFile = File(imagen.path));
  }

  Future<void> _publicar() async {
    if (_videoFile == null) {
      _mostrarError('Selecciona un video');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _subiendo = true;
      _progreso = 0;
    });

    // Subir video con progreso
    final urlVideo = await _service.subirVideo(
      _videoFile!,
      onProgress: (p) => setState(() => _progreso = p * 0.8),
    );

    if (urlVideo == null) {
      _mostrarError('Error al subir el video');
      setState(() => _subiendo = false);
      return;
    }

    // Subir miniatura si hay
    String urlMiniatura = '';
    if (_miniaturaFile != null) {
      setState(() => _progreso = 0.85);
      urlMiniatura = await _service.subirMiniatura(_miniaturaFile!) ?? '';
    }

    setState(() => _progreso = 0.95);

    final reel = ReelModel(
      urlVideo: urlVideo,
      urlMiniatura: urlMiniatura,
      titulo: _tituloCtrl.text.trim(),
      descripcion: _descripcionCtrl.text.trim(),
      usuarioId: UsuarioConfig.usuarioId,
      nombreUsuario: UsuarioConfig.nombreUsuario,
      avatarUsuario: UsuarioConfig.avatarUsuario,
      categoria: _categoriaSeleccionada,
      estado: 'pendiente',
      creadoEn: Timestamp.now(),
    );

    final id = await _service.crear(reel);
    setState(() => _progreso = 1.0);

    if (!mounted) return;

    if (id != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Reel enviado a revisión. Se publicará cuando sea aprobado.',
              style: GoogleFonts.poppins()),
          backgroundColor: const Color(0xFF005DB9),
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context);
    } else {
      _mostrarError('Error al crear el reel');
      setState(() => _subiendo = false);
    }
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins()),
      backgroundColor: const Color(0xFFF32836),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text('Crear Reel',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        actions: [
          if (!_subiendo)
            TextButton(
              onPressed: _publicar,
              child: Text('Publicar',
                  style: GoogleFonts.poppins(
                      color: const Color(0xFF005DB9),
                      fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: _subiendo
          ? _buildSubiendo()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSelectorVideo(),
              const SizedBox(height: 16),
              _buildCampos(),
              const SizedBox(height: 16),
              _buildSelectorCategoria(),
              const SizedBox(height: 16),
              _buildSelectorMiniatura(),
              const SizedBox(height: 32),
              _buildBotonPublicar(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubiendo() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF005DB9), Color(0xFF009BDF)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_upload_rounded,
                  color: Colors.white, size: 48),
            ),
            const SizedBox(height: 32),
            Text('Subiendo reel...',
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('${(_progreso * 100).toInt()}%',
                style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF005DB9))),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _progreso,
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation(Color(0xFF005DB9)),
              ),
            ),
            const SizedBox(height: 16),
            Text('No cierres la aplicación',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectorVideo() {
    return GestureDetector(
      onTap: _seleccionarVideo,
      child: Container(
        height: 320,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(20),
        ),
        child: _previewCtrl != null && _previewCtrl!.value.isInitialized
            ? Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _previewCtrl!.value.size.width,
                    height: _previewCtrl!.value.size.height,
                    child: VideoPlayer(_previewCtrl!),
                  ),
                ),
              ),
            ),
            // Overlay botón cambiar
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                onTap: _seleccionarVideo,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Cambiar',
                      style: GoogleFonts.poppins(
                          color: Colors.white, fontSize: 12)),
                ),
              ),
            ),
            // Duración
            Positioned(
              bottom: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatDuracion(
                      _previewCtrl!.value.duration),
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.video_library_rounded,
                  color: Colors.white60, size: 32),
            ),
            const SizedBox(height: 16),
            Text('Toca para seleccionar un video',
                style: GoogleFonts.poppins(
                    color: Colors.white60, fontSize: 15)),
            const SizedBox(height: 6),
            Text('Máximo 3 minutos',
                style: GoogleFonts.poppins(
                    color: Colors.white38, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildCampos() {
    return Column(
      children: [
        TextFormField(
          controller: _tituloCtrl,
          decoration: InputDecoration(
            labelText: 'Título',
            labelStyle: GoogleFonts.poppins(),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
          style: GoogleFonts.poppins(),
          validator: (v) =>
          v == null || v.trim().isEmpty ? 'El título es obligatorio' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _descripcionCtrl,
          decoration: InputDecoration(
            labelText: 'Descripción (opcional)',
            labelStyle: GoogleFonts.poppins(),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
          style: GoogleFonts.poppins(),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildSelectorCategoria() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Categoría',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ReelsService.categorias.map((cat) {
              final seleccionada =
                  _categoriaSeleccionada == cat['valor'];
              return GestureDetector(
                onTap: () =>
                    setState(() => _categoriaSeleccionada = cat['valor']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: seleccionada
                        ? const Color(0xFF005DB9)
                        : const Color(0xFFF5F6FA),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: seleccionada
                          ? const Color(0xFF005DB9)
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    cat['etiqueta']!,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: seleccionada
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: seleccionada
                          ? Colors.white
                          : const Color(0xFF1A1A2E),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorMiniatura() {
    return GestureDetector(
      onTap: _seleccionarMiniatura,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            if (_miniaturaFile != null)
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(15)),
                child: Image.file(_miniaturaFile!,
                    width: 80, height: 80, fit: BoxFit.cover),
              )
            else
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(15)),
                ),
                child: Icon(Icons.image_outlined,
                    color: Colors.grey[400], size: 28),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Miniatura',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(
                    _miniaturaFile != null
                        ? 'Toca para cambiar'
                        : 'Opcional — se usa como preview',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Icon(Icons.chevron_right_rounded,
                  color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotonPublicar() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _publicar,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF005DB9),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
        child: Text('Enviar a revisión',
            style: GoogleFonts.poppins(
                fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }

  String _formatDuracion(Duration d) {
    final min = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seg = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$min:$seg';
  }
}