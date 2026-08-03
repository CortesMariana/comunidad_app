import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/publicacion_model.dart';
import '../../services/publicaciones/publicaciones_service.dart';
import '../../config/usuario_config.dart';

class CrearPublicacionScreen extends StatefulWidget {
  const CrearPublicacionScreen({super.key});

  @override
  State<CrearPublicacionScreen> createState() =>
      _CrearPublicacionScreenState();
}

class _CrearPublicacionScreenState extends State<CrearPublicacionScreen> {
  final _contenidoCtrl = TextEditingController();
  final _service = PublicacionesService();
  final _picker = ImagePicker();

  File? _imagenFile;
  String _categoria = 'anuncios';
  bool _programada = false;
  DateTime _fechaProgramada = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _horaProgramada = TimeOfDay.now();
  bool _subiendo = false;

  static const _categorias = [
    {'valor': 'anuncios', 'etiqueta': '📢 Anuncios'},
    {'valor': 'capacitacion', 'etiqueta': '📚 Capacitación'},
    {'valor': 'cultura', 'etiqueta': '🎉 Cultura'},
    {'valor': 'reconocimiento', 'etiqueta': '🏆 Reconocimiento'},
  ];

  @override
  void dispose() {
    _contenidoCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarImagen() async {
    final img = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 85);
    if (img != null) setState(() => _imagenFile = File(img.path));
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaProgramada,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (fecha != null) setState(() => _fechaProgramada = fecha);
  }

  Future<void> _seleccionarHora() async {
    final hora =
    await showTimePicker(context: context, initialTime: _horaProgramada);
    if (hora != null) setState(() => _horaProgramada = hora);
  }

  DateTime get _fechaHoraProgramada => DateTime(
    _fechaProgramada.year,
    _fechaProgramada.month,
    _fechaProgramada.day,
    _horaProgramada.hour,
    _horaProgramada.minute,
  );

  Future<void> _publicar() async {
    if (_contenidoCtrl.text.trim().isEmpty) {
      _snack('Escribe algo para publicar', error: true);
      return;
    }
    setState(() => _subiendo = true);

    String? urlImagen;
    if (_imagenFile != null) {
      urlImagen = await _service.subirImagen(_imagenFile!);
    }

    final pub = PublicacionModel(
      usuarioId: UsuarioConfig.usuarioId,
      nombreUsuario: UsuarioConfig.nombreUsuario,
      avatarUsuario: UsuarioConfig.avatarUsuario,
      contenido: _contenidoCtrl.text.trim(),
      urlImagen: urlImagen,
      categoria: _categoria,
      estado: 'pendiente',
      estaProgramado: _programada,
      fechaProgramada: _programada ? _fechaHoraProgramada : null,
      creadoEn: Timestamp.now(),
    );

    final id = await _service.crear(pub);
    if (!mounted) return;
    setState(() => _subiendo = false);

    if (id != null) {
      _snack(_programada
          ? 'Publicación programada enviada a revisión'
          : 'Publicación enviada a revisión');
      Navigator.pop(context);
    } else {
      _snack('Error al crear la publicación', error: true);
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
        title: Text('Nueva publicación',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        actions: [
          if (!_subiendo)
            TextButton(
              onPressed: _publicar,
              child: Text('Publicar',
                  style: GoogleFonts.poppins(
                      color: const Color(0xFF005DB9),
                      fontWeight: FontWeight.w600,
                      fontSize: 15)),
            ),
        ],
      ),
      body: _subiendo
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Autor ────────────────────────────────────────────────
            _buildAutor(),
            const SizedBox(height: 16),

            // ── Texto ────────────────────────────────────────────────
            _buildCampoTexto(),
            const SizedBox(height: 16),

            // ── Imagen ───────────────────────────────────────────────
            _buildSelectorImagen(),
            const SizedBox(height: 16),

            // ── Categoría ────────────────────────────────────────────
            _buildCategorias(),
            const SizedBox(height: 16),

            // ── Programar ────────────────────────────────────────────
            _buildProgramar(),
            const SizedBox(height: 32),

            // ── Botón ────────────────────────────────────────────────
            _buildBoton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAutor() {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xFF005DB9),
          backgroundImage: UsuarioConfig.avatarUsuario.isNotEmpty
              ? NetworkImage(UsuarioConfig.avatarUsuario)
              : null,
          child: UsuarioConfig.avatarUsuario.isEmpty
              ? Text(
              UsuarioConfig.nombreUsuario.isNotEmpty
                  ? UsuarioConfig.nombreUsuario[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold))
              : null,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(UsuarioConfig.nombreUsuario,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, fontSize: 15)),
            Text('Pendiente de aprobación',
                style: GoogleFonts.poppins(
                    fontSize: 11, color: Colors.orange[600])),
          ],
        ),
      ],
    );
  }

  Widget _buildCampoTexto() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: _contenidoCtrl,
        maxLines: 6,
        minLines: 4,
        decoration: InputDecoration(
          hintText: '¿Qué quieres compartir con tu comunidad?',
          hintStyle:
          GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
        style: GoogleFonts.poppins(fontSize: 14),
      ),
    );
  }

  Widget _buildSelectorImagen() {
    return GestureDetector(
      onTap: _seleccionarImagen,
      child: Container(
        height: _imagenFile != null ? 200 : 80,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: _imagenFile != null
            ? Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.file(_imagenFile!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => setState(() => _imagenFile = null),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close,
                      color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                color: Colors.grey[400], size: 28),
            const SizedBox(width: 10),
            Text('Agregar imagen',
                style: GoogleFonts.poppins(
                    color: Colors.grey[500], fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorias() {
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
            children: _categorias.map((cat) {
              final sel = _categoria == cat['valor'];
              return GestureDetector(
                onTap: () => setState(() => _categoria = cat['valor']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 27, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel
                        ? const Color(0xFF005DB9)
                        : const Color(0xFFF5F6FA),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: sel
                          ? const Color(0xFF005DB9)
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    cat['etiqueta']!,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight:
                      sel ? FontWeight.w600 : FontWeight.normal,
                      color: sel ? Colors.white : const Color(0xFF1A1A2E),
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

  Widget _buildProgramar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.schedule_rounded,
                  color: const Color(0xFF005DB9), size: 20),
              const SizedBox(width: 10),
              Text('Programar publicación',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              const Spacer(),
              Switch(
                value: _programada,
                onChanged: (v) => setState(() => _programada = v),
                activeColor: const Color(0xFF005DB9),
              ),
            ],
          ),
          if (_programada) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _seleccionarFecha,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F6FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 16, color: Color(0xFF005DB9)),
                          const SizedBox(width: 8),
                          Text(
                            '${_fechaProgramada.day}/${_fechaProgramada.month}/${_fechaProgramada.year}',
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: _seleccionarHora,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F6FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_rounded,
                              size: 16, color: Color(0xFF005DB9)),
                          const SizedBox(width: 8),
                          Text(
                            '${_horaProgramada.hour.toString().padLeft(2, '0')}:${_horaProgramada.minute.toString().padLeft(2, '0')}',
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF005DB9).withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 14, color: Color(0xFF005DB9)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'La publicación pasará por revisión y aparecerá en la fecha indicada una vez aprobada.',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: const Color(0xFF005DB9)),
                    ),
                  ),
                ],
              ),
            ),
          ],
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