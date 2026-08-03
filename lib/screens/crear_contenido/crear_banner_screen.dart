import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/banner_model.dart';
import '../../services/banners/banners_service.dart';
import '../../config/usuario_config.dart';

class CrearBannerScreen extends StatefulWidget {
  const CrearBannerScreen({super.key});

  @override
  State<CrearBannerScreen> createState() => _CrearBannerScreenState();
}

class _CrearBannerScreenState extends State<CrearBannerScreen> {
  final _tituloCtrl = TextEditingController();
  final _subtituloCtrl = TextEditingController();
  final _urlAccionCtrl = TextEditingController();
  final _service = BannersService();
  final _picker = ImagePicker();

  File? _imagenFile;
  DateTime? _expiraEn;
  bool _subiendo = false;

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _subtituloCtrl.dispose();
    _urlAccionCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarImagen() async {
    final img = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 90);
    if (img != null) setState(() => _imagenFile = File(img.path));
  }

  Future<void> _seleccionarExpiracion() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (fecha != null) setState(() => _expiraEn = fecha);
  }

  Future<void> _publicar() async {
    if (_tituloCtrl.text.trim().isEmpty) {
      _snack('El título es obligatorio', error: true);
      return;
    }
    if (_imagenFile == null) {
      _snack('Selecciona una imagen para el banner', error: true);
      return;
    }
    setState(() => _subiendo = true);

    final urlImagen = await _service.subirImagen(_imagenFile!);
    if (urlImagen == null) {
      _snack('Error al subir la imagen', error: true);
      setState(() => _subiendo = false);
      return;
    }

    final banner = BannerModel(
      usuarioId: UsuarioConfig.usuarioId,
      nombreUsuario: UsuarioConfig.nombreUsuario,
      titulo: _tituloCtrl.text.trim(),
      subtitulo: _subtituloCtrl.text.trim().isNotEmpty
          ? _subtituloCtrl.text.trim()
          : null,
      urlImagen: urlImagen,
      urlAccion: _urlAccionCtrl.text.trim().isNotEmpty
          ? _urlAccionCtrl.text.trim()
          : null,
      estado: 'pendiente',
      activo: true,
      orden: 0,
      creadoEn: Timestamp.now(),
      expiraEn: _expiraEn != null ? Timestamp.fromDate(_expiraEn!) : null,
    );

    final id = await _service.crear(banner);
    if (!mounted) return;
    setState(() => _subiendo = false);

    if (id != null) {
      _snack('Banner enviado a revisión');
      Navigator.pop(context);
    } else {
      _snack('Error al crear el banner', error: true);
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
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text('Crear Banner',
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
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Preview imagen ───────────────────────────────────────
            _buildPreviewImagen(),
            const SizedBox(height: 16),

            // ── Campos ───────────────────────────────────────────────
            _buildCampos(),
            const SizedBox(height: 16),

            // ── Expiración ───────────────────────────────────────────
            _buildExpiracion(),
            const SizedBox(height: 32),

            // ── Botón ────────────────────────────────────────────────
            _buildBoton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewImagen() {
    return GestureDetector(
      onTap: _seleccionarImagen,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(20),
          image: _imagenFile != null
              ? DecorationImage(
              image: FileImage(_imagenFile!), fit: BoxFit.cover)
              : null,
        ),
        child: _imagenFile != null
            ? Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.5),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_tituloCtrl.text.isNotEmpty)
                    Text(_tituloCtrl.text,
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                  if (_subtituloCtrl.text.isNotEmpty)
                    Text(_subtituloCtrl.text,
                        style: GoogleFonts.poppins(
                            color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Cambiar imagen',
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontSize: 12)),
              ),
            ),
          ],
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_photo_alternate_outlined,
                color: Colors.white38, size: 48),
            const SizedBox(height: 12),
            Text('Toca para agregar imagen del banner',
                style: GoogleFonts.poppins(
                    color: Colors.white38, fontSize: 14)),
            const SizedBox(height: 4),
            Text('Recomendado: 1200 x 400 px',
                style: GoogleFonts.poppins(
                    color: Colors.white24, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildCampos() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          TextField(
            controller: _tituloCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Título *',
              labelStyle: GoogleFonts.poppins(),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            style: GoogleFonts.poppins(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _subtituloCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Subtítulo (opcional)',
              labelStyle: GoogleFonts.poppins(),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            style: GoogleFonts.poppins(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _urlAccionCtrl,
            decoration: InputDecoration(
              labelText: 'URL de acción (opcional)',
              hintText: 'https://...',
              labelStyle: GoogleFonts.poppins(),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.link_rounded),
            ),
            style: GoogleFonts.poppins(),
            keyboardType: TextInputType.url,
          ),
        ],
      ),
    );
  }

  Widget _buildExpiracion() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_outlined,
              color: Color(0xFF005DB9), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Fecha de expiración',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                Text(
                  _expiraEn != null
                      ? '${_expiraEn!.day}/${_expiraEn!.month}/${_expiraEn!.year}'
                      : 'Sin fecha límite',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Row(
            children: [
              if (_expiraEn != null)
                GestureDetector(
                  onTap: () => setState(() => _expiraEn = null),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.grey, size: 20),
                ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _seleccionarExpiracion,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF005DB9).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('Elegir',
                      style: GoogleFonts.poppins(
                          color: const Color(0xFF005DB9),
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBoton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _publicar,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF005DB9),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text('Enviar a revisión',
            style: GoogleFonts.poppins(
                fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }
}