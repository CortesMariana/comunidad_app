import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/historia_model.dart';
import '../../services/historias/historias_service.dart';
import '../../config/usuario_config.dart';

class CrearHistoriaScreen extends StatefulWidget {
  const CrearHistoriaScreen({super.key});

  @override
  State<CrearHistoriaScreen> createState() => _CrearHistoriaScreenState();
}

class _CrearHistoriaScreenState extends State<CrearHistoriaScreen> {
  final _textoCtrl = TextEditingController();
  final _service = HistoriasService();
  final _picker = ImagePicker();

  File? _mediaFile;
  bool _esVideo = false;
  bool _subiendo = false;

  @override
  void dispose() {
    _textoCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarImagen() async {
    final img = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 85);
    if (img != null) {
      setState(() {
        _mediaFile = File(img.path);
        _esVideo = false;
      });
    }
  }

  Future<void> _seleccionarVideo() async {
    final vid = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 30));
    if (vid != null) {
      setState(() {
        _mediaFile = File(vid.path);
        _esVideo = true;
      });
    }
  }

  Future<void> _publicar() async {
    if (_mediaFile == null) {
      _snack('Selecciona una imagen o video', error: true);
      return;
    }
    setState(() => _subiendo = true);

    final urlMedia =
    await _service.subirMedia(_mediaFile!, esVideo: _esVideo);
    if (urlMedia == null) {
      _snack('Error al subir el archivo', error: true);
      setState(() => _subiendo = false);
      return;
    }

    final ahora = Timestamp.now();
    final historia = HistoriaModel(
      usuarioId: UsuarioConfig.usuarioId,
      nombreUsuario: UsuarioConfig.nombreUsuario,
      avatarUsuario: UsuarioConfig.avatarUsuario,
      tipo: _esVideo ? 'video' : 'imagen',
      urlMedia: urlMedia,
      texto: _textoCtrl.text.trim(),
      estado: 'pendiente',
      creadoEn: ahora,
      expiraEn: Timestamp.fromDate(
          DateTime.now().add(const Duration(hours: 24))),
    );

    final id = await _service.crear(historia);
    if (!mounted) return;
    setState(() => _subiendo = false);

    if (id != null) {
      _snack('Historia enviada a revisión');
      Navigator.pop(context);
    } else {
      _snack('Error al crear la historia', error: true);
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins()),
      backgroundColor:
      error ? const Color(0xFFF32836) : const Color(0xFF005DB9),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text('Nueva historia',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700, color: Colors.white)),
        actions: [
          if (!_subiendo && _mediaFile != null)
            TextButton(
              onPressed: _publicar,
              child: Text('Enviar',
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: _subiendo
          ? const Center(
          child: CircularProgressIndicator(color: Colors.white))
          : Column(
        children: [
          // ── Preview ──────────────────────────────────────────────
          Expanded(child: _buildPreview()),

          // ── Controles abajo ───────────────────────────────────────
          _buildControles(),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    if (_mediaFile == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                size: 80, color: Colors.white24),
            const SizedBox(height: 16),
            Text('Selecciona una imagen o video',
                style: GoogleFonts.poppins(
                    color: Colors.white38, fontSize: 16)),
          ],
        ),
      );
    }
    if (_esVideo) {
      return Center(
        child: Icon(Icons.play_circle_outline,
            size: 80, color: Colors.white60),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(_mediaFile!, fit: BoxFit.contain),
        if (_textoCtrl.text.isNotEmpty)
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_textoCtrl.text,
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center),
            ),
          ),
      ],
    );
  }

  Widget _buildControles() {
    return Container(
      color: Colors.black,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Texto superpuesto
          TextField(
            controller: _textoCtrl,
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.poppins(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Agrega un texto a tu historia...',
              hintStyle: GoogleFonts.poppins(
                  color: Colors.white38, fontSize: 13),
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          // Botones selección
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _seleccionarImagen,
                  icon: const Icon(Icons.photo_outlined,
                      color: Colors.white),
                  label: Text('Imagen',
                      style: GoogleFonts.poppins(color: Colors.white)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white30),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _seleccionarVideo,
                  icon: const Icon(Icons.videocam_outlined,
                      color: Colors.white),
                  label: Text('Video',
                      style: GoogleFonts.poppins(color: Colors.white)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white30),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _mediaFile != null ? _publicar : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF32836),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Enviar a revisión',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}