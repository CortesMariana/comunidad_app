import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../services/uniformes/uniformes_service.dart';
import '../../../config/usuario_config.dart';

class UniformesScreen extends StatefulWidget {
  const UniformesScreen({super.key});

  @override
  State<UniformesScreen> createState() => _UniformesScreenState();
}

class _UniformesScreenState extends State<UniformesScreen>
    with SingleTickerProviderStateMixin {
  final _service = UniformesService();
  late TabController _tabController;

  List<ProductoUniformeModel> _catalogo = [];
  List<SolicitudUniformeModel> _solicitudes = [];
  final List<ItemCarritoModel> _carrito = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargar();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final results = await Future.wait([
      _service.obtenerCatalogo(),
      _service.obtenerSolicitudes(UsuarioConfig.usuarioId),
    ]);
    setState(() {
      _catalogo = results[0] as List<ProductoUniformeModel>;
      _solicitudes = results[1] as List<SolicitudUniformeModel>;
      _cargando = false;
    });
  }

  int get _totalCarrito =>
      _carrito.fold(0, (sum, i) => sum + i.cantidad);
  double get _totalPrecio =>
      _carrito.fold(0.0, (sum, i) => sum + i.subtotal);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text('Uniformes',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Color(0xFF005DB9)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_carrito.isNotEmpty)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined,
                      color: Color(0xFF005DB9)),
                  onPressed: _abrirCarrito,
                ),
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF32836),
                      shape: BoxShape.circle,
                    ),
                    child: Text('$_totalCarrito',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w600, fontSize: 13),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 13),
          labelColor: const Color(0xFF005DB9),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF005DB9),
          indicatorWeight: 2.5,
          tabs: const [
            Tab(text: 'Catálogo'),
            Tab(text: 'Mis pedidos'),
          ],
        ),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _cargar,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildCatalogo(),
            _buildPedidos(),
          ],
        ),
      ),
      bottomNavigationBar: _carrito.isNotEmpty
          ? _buildBarraCarrito()
          : null,
    );
  }

  // ── CATÁLOGO ──────────────────────────────────────────────────────────────

  Widget _buildCatalogo() {
    if (_catalogo.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.checkroom_outlined,
                size: 64, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('Sin uniformes disponibles',
                style: GoogleFonts.poppins(
                    color: Colors.grey[400], fontSize: 15)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: _catalogo.length,
      itemBuilder: (context, i) => _TarjetaProducto(
        producto: _catalogo[i],
        onAgregar: () => _abrirSelector(_catalogo[i]),
      ),
    );
  }

  void _abrirSelector(ProductoUniformeModel producto) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SelectorVariante(
        producto: producto,
        onAgregar: (item) {
          setState(() {
            final existente = _carrito.firstWhere(
                  (c) => c.varianteId == item.varianteId,
              orElse: () => ItemCarritoModel(
                uniformeId: '',
                varianteId: '',
                nombreUniforme: '',
                foto: '',
                precio: 0,
                talla: '',
                colorHex: '',
              ),
            );
            if (existente.varianteId == item.varianteId &&
                existente.varianteId.isNotEmpty) {
              existente.cantidad += item.cantidad;
            } else {
              _carrito.add(item);
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Agregado al carrito',
                style: GoogleFonts.poppins()),
            backgroundColor: const Color(0xFF00B37E),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ));
        },
      ),
    );
  }

  // ── CARRITO ───────────────────────────────────────────────────────────────

  Widget _buildBarraCarrito() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$_totalCarrito artículos',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.grey[500])),
              Text(
                '\$${_totalPrecio.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF005DB9)),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _abrirCarrito,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF005DB9),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Ver carrito',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  void _abrirCarrito() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ModalCarrito(
        carrito: _carrito,
        onCambiarCantidad: (item, delta) {
          setState(() {
            item.cantidad += delta;
            if (item.cantidad <= 0) _carrito.remove(item);
          });
        },
        onEliminar: (item) => setState(() => _carrito.remove(item)),
        onPedido: () async {
          final detalles = _carrito
              .map((c) => DetallePedidoModel(
            uniformeId: c.uniformeId,
            varianteId: c.varianteId,
            cantidad: c.cantidad,
          ))
              .toList();
          final ok = await _service.crearSolicitud(
            colaboradorId: UsuarioConfig.usuarioId,
            detalles: detalles,
          );
          if (!mounted) return;
          if (ok) {
            setState(() => _carrito.clear());
            _cargar();
            _tabController.animateTo(1);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Pedido enviado correctamente',
                  style: GoogleFonts.poppins()),
              backgroundColor: const Color(0xFF00B37E),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Error al enviar el pedido',
                  style: GoogleFonts.poppins()),
              backgroundColor: const Color(0xFFF32836),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ));
          }
        },
      ),
    );
  }

  // ── PEDIDOS ───────────────────────────────────────────────────────────────

  Widget _buildPedidos() {
    if (_solicitudes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 64, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('Sin pedidos aún',
                style: GoogleFonts.poppins(
                    color: Colors.grey[400], fontSize: 15)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _solicitudes.length,
      itemBuilder: (context, i) => _TarjetaPedido(
        solicitud: _solicitudes[i],
        onCancelar: () => _cancelar(_solicitudes[i]),
        onRecibir: () => _recibir(_solicitudes[i]),
      ),
    );
  }

  Future<void> _cancelar(SolicitudUniformeModel s) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Cancelar pedido',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text('¿Deseas cancelar este pedido?',
            style: GoogleFonts.poppins(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No',
                style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF32836),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Cancelar pedido',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmado != true) return;
    final ok = await _service.cancelarSolicitud(s.id);
    if (!mounted) return;
    if (ok) _cargar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Pedido cancelado' : 'Error al cancelar',
          style: GoogleFonts.poppins()),
      backgroundColor:
      ok ? Colors.grey : const Color(0xFFF32836),
      behavior: SnackBarBehavior.floating,
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> _recibir(SolicitudUniformeModel s) async {
    final codigo = await _service.generarCodigo(s.id);
    if (!mounted) return;
    if (codigo == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al generar código',
            style: GoogleFonts.poppins()),
        backgroundColor: const Color(0xFFF32836),
      ));
      return;
    }
    showDialog(
      context: context,
      builder: (_) => _DialogQR(codigo: codigo),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TARJETA PRODUCTO CATÁLOGO
// ─────────────────────────────────────────────────────────────────────────────

class _TarjetaProducto extends StatelessWidget {
  final ProductoUniformeModel producto;
  final VoidCallback onAgregar;

  const _TarjetaProducto(
      {required this.producto, required this.onAgregar});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onAgregar,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16)),
                child: producto.fotoPrincipal.isNotEmpty
                    ? Image.network(
                  producto.fotoPrincipal,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _placeholder(),
                )
                    : _placeholder(),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto.nombre,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: const Color(0xFF1A1A2E)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '\$${producto.precioMinimo.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF005DB9)),
                      ),
                      const Spacer(),
                      // Colores disponibles
                      ...producto.coloresUnicos.take(4).map(
                            (c) => Container(
                          width: 12,
                          height: 12,
                          margin: const EdgeInsets.only(left: 3),
                          decoration: BoxDecoration(
                            color: c.color,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.grey[200]!,
                                width: 0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey[100],
      child: const Center(
          child: Icon(Icons.checkroom_outlined,
              color: Colors.grey, size: 40)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SELECTOR DE VARIANTE (estilo Shein)
// ─────────────────────────────────────────────────────────────────────────────

class _SelectorVariante extends StatefulWidget {
  final ProductoUniformeModel producto;
  final Function(ItemCarritoModel) onAgregar;

  const _SelectorVariante(
      {required this.producto, required this.onAgregar});

  @override
  State<_SelectorVariante> createState() => _SelectorVarianteState();
}

class _SelectorVarianteState extends State<_SelectorVariante> {
  ColorUnicoModel? _colorSeleccionado;
  String? _tallaSeleccionada;
  int _cantidad = 1;
  int _fotoActual = 0;

  List<String> get _tallasDisponibles {
    if (_colorSeleccionado == null) {
      return widget.producto.tallasDisponibles;
    }
    return widget.producto.tallasParaColor(_colorSeleccionado!);
  }

  VarianteModel? get _varianteActual =>
      widget.producto.varianteParaSeleccion(
          _tallaSeleccionada, _colorSeleccionado);

  List<String> get _fotos {
    final v = _varianteActual;
    if (v != null && v.fotos.isNotEmpty) return v.fotos;
    if (v?.fotoPortadaUrl != null) return [v!.fotoPortadaUrl!];
    final foto = widget.producto.fotoPrincipal;
    return foto.isNotEmpty ? [foto] : [];
  }

  bool get _puedeAgregar =>
      _colorSeleccionado != null && _tallaSeleccionada != null;

  @override
  Widget build(BuildContext context) {
    final colores = widget.producto.coloresUnicos;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Galería de fotos
                  _buildGaleria(),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nombre y precio
                        Text(widget.producto.nombre,
                            style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1A1A2E))),
                        const SizedBox(height: 4),
                        Text(
                          _varianteActual != null
                              ? '\$${_varianteActual!.precio.toStringAsFixed(2)}'
                              : 'Desde \$${widget.producto.precioMinimo.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF005DB9)),
                        ),
                        const SizedBox(height: 20),

                        // Selector de color
                        if (colores.isNotEmpty) ...[
                          Row(
                            children: [
                              Text('Color',
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14)),
                              if (_colorSeleccionado != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: _colorSeleccionado!.color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.grey[300]!),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: colores.map((c) {
                              final seleccionado =
                                  _colorSeleccionado?.hexRepresentativo ==
                                      c.hexRepresentativo;
                              return GestureDetector(
                                onTap: () => setState(() {
                                  _colorSeleccionado = c;
                                  // Si la talla actual no está disponible para este color, resetear
                                  if (_tallaSeleccionada != null &&
                                      !widget.producto
                                          .tallasParaColor(c)
                                          .contains(_tallaSeleccionada)) {
                                    _tallaSeleccionada = null;
                                  }
                                  _fotoActual = 0;
                                }),
                                child: AnimatedContainer(
                                  duration:
                                  const Duration(milliseconds: 200),
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: c.color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: seleccionado
                                          ? const Color(0xFF005DB9)
                                          : Colors.grey[300]!,
                                      width: seleccionado ? 3 : 1,
                                    ),
                                    boxShadow: seleccionado
                                        ? [
                                      BoxShadow(
                                        color: c.color
                                            .withOpacity(0.4),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      )
                                    ]
                                        : null,
                                  ),
                                  child: seleccionado
                                      ? Icon(
                                    Icons.check_rounded,
                                    color: c.color.computeLuminance() >
                                        0.5
                                        ? Colors.black
                                        : Colors.white,
                                    size: 18,
                                  )
                                      : null,
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Selector de talla
                        Text('Talla',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _tallasDisponibles.map((t) {
                            final seleccionada =
                                _tallaSeleccionada == t;
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _tallaSeleccionada = t),
                              child: AnimatedContainer(
                                duration:
                                const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: seleccionada
                                      ? const Color(0xFF005DB9)
                                      : Colors.white,
                                  borderRadius:
                                  BorderRadius.circular(10),
                                  border: Border.all(
                                    color: seleccionada
                                        ? const Color(0xFF005DB9)
                                        : Colors.grey[300]!,
                                    width: seleccionada ? 2 : 1,
                                  ),
                                ),
                                child: Text(
                                  t,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: seleccionada
                                        ? Colors.white
                                        : const Color(0xFF1A1A2E),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),

                        // Cantidad
                        Row(
                          children: [
                            Text('Cantidad',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14)),
                            const Spacer(),
                            _BotonCantidad(
                              icono: Icons.remove_rounded,
                              onTap: () {
                                if (_cantidad > 1) {
                                  setState(() => _cantidad--);
                                }
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16),
                              child: Text('$_cantidad',
                                  style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                            ),
                            _BotonCantidad(
                              icono: Icons.add_rounded,
                              onTap: () =>
                                  setState(() => _cantidad++),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Descripción
                        if (widget.producto.descripcion.isNotEmpty) ...[
                          Text('Descripción',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
                          const SizedBox(height: 6),
                          Text(widget.producto.descripcion,
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                  height: 1.5)),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Botón agregar
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -4)),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _puedeAgregar
                    ? () {
                  final variante = _varianteActual;
                  if (variante == null) return;
                  widget.onAgregar(ItemCarritoModel(
                    uniformeId: widget.producto.id,
                    varianteId: variante.id,
                    nombreUniforme: widget.producto.nombre,
                    foto: variante.fotoPortadaUrl ??
                        (variante.fotos.isNotEmpty
                            ? variante.fotos.first
                            : widget.producto.fotoPrincipal),
                    precio: variante.precio,
                    talla: _tallaSeleccionada!,
                    colorHex:
                    _colorSeleccionado!.hexRepresentativo,
                    cantidad: _cantidad,
                  ));
                  Navigator.pop(context);
                }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005DB9),
                  disabledBackgroundColor: Colors.grey[300],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  _puedeAgregar
                      ? 'Agregar al carrito · \$${((_varianteActual?.precio ?? 0) * _cantidad).toStringAsFixed(2)}'
                      : 'Selecciona color y talla',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGaleria() {
    final fotos = _fotos;
    if (fotos.isEmpty) {
      return Container(
        height: 280,
        color: Colors.grey[100],
        child: const Center(
            child: Icon(Icons.checkroom_outlined,
                color: Colors.grey, size: 60)),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 300,
          child: PageView.builder(
            itemCount: fotos.length,
            onPageChanged: (i) => setState(() => _fotoActual = i),
            itemBuilder: (_, i) => Image.network(
              fotos[i],
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey[100],
                child: const Icon(Icons.checkroom_outlined,
                    color: Colors.grey),
              ),
            ),
          ),
        ),
        if (fotos.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              fotos.length,
                  (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _fotoActual == i ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _fotoActual == i
                      ? const Color(0xFF005DB9)
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MODAL CARRITO
// ─────────────────────────────────────────────────────────────────────────────

class _ModalCarrito extends StatefulWidget {
  final List<ItemCarritoModel> carrito;
  final Function(ItemCarritoModel, int) onCambiarCantidad;
  final Function(ItemCarritoModel) onEliminar;
  final Future<void> Function() onPedido;

  const _ModalCarrito({
    required this.carrito,
    required this.onCambiarCantidad,
    required this.onEliminar,
    required this.onPedido,
  });

  @override
  State<_ModalCarrito> createState() => _ModalCarritoState();
}

class _ModalCarritoState extends State<_ModalCarrito> {
  bool _enviando = false;

  double get _total =>
      widget.carrito.fold(0.0, (sum, i) => sum + i.subtotal);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2)),
                ),
                const Spacer(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Text('Mi carrito',
                    style: GoogleFonts.poppins(
                        fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF005DB9).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${widget.carrito.length}',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF005DB9),
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.carrito.length,
              itemBuilder: (context, i) {
                final item = widget.carrito[i];
                return StatefulBuilder(
                  builder: (context, setS) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey[100]!),
                    ),
                    child: Row(
                      children: [
                        // Foto
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: item.foto.isNotEmpty
                              ? Image.network(item.foto,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover)
                              : Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey[200],
                              child: const Icon(
                                  Icons.checkroom_outlined,
                                  color: Colors.grey)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(item.nombreUniforme,
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Color(int.parse(
                                          'FF${item.colorHex}',
                                          radix: 16)),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.grey[300]!),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(item.talla,
                                      style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: Colors.grey[500])),
                                  const SizedBox(width: 8),
                                  Text(
                                    '\$${item.precio.toStringAsFixed(2)}',
                                    style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color:
                                        const Color(0xFF005DB9)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            GestureDetector(
                              onTap: () => widget.onEliminar(item),
                              child: Icon(Icons.delete_outline_rounded,
                                  color: Colors.grey[400], size: 18),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _BotonCantidad(
                                  icono: Icons.remove_rounded,
                                  onTap: () {
                                    widget.onCambiarCantidad(item, -1);
                                    setS(() {});
                                  },
                                  pequenio: true,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8),
                                  child: Text('${item.cantidad}',
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13)),
                                ),
                                _BotonCantidad(
                                  icono: Icons.add_rounded,
                                  onTap: () {
                                    widget.onCambiarCantidad(item, 1);
                                    setS(() {});
                                  },
                                  pequenio: true,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -4)),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text('Total',
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600])),
                    const Spacer(),
                    Text('\$${_total.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF005DB9))),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _enviando
                        ? null
                        : () async {
                      setState(() => _enviando = true);
                      Navigator.pop(context);
                      await widget.onPedido();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF005DB9),
                      foregroundColor: Colors.white,
                      padding:
                      const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _enviando
                        ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white))
                        : Text('Realizar pedido',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TARJETA PEDIDO
// ─────────────────────────────────────────────────────────────────────────────

class _TarjetaPedido extends StatelessWidget {
  final SolicitudUniformeModel solicitud;
  final VoidCallback onCancelar;
  final VoidCallback onRecibir;

  const _TarjetaPedido({
    required this.solicitud,
    required this.onCancelar,
    required this.onRecibir,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF005DB9).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.receipt_long_rounded,
                      color: Color(0xFF005DB9), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pedido · ${solicitud.detalles.length} ${solicitud.detalles.length == 1 ? "artículo" : "artículos"}',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: const Color(0xFF1A1A2E)),
                      ),
                      Text(
                        _fmtFecha(solicitud.fechaSolicitud),
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                    solicitud.colorEstado.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(solicitud.estado,
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: solicitud.colorEstado)),
                ),
              ],
            ),
          ),

          // Detalles
          if (solicitud.detalles.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: solicitud.detalles
                    .take(3)
                    .map((d) => _FilaDetalle(detalle: d))
                    .toList(),
              ),
            ),

          // Total
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Text('Total',
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: Colors.grey[500])),
                const Spacer(),
                Text('\$${solicitud.total.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF005DB9))),
              ],
            ),
          ),

          // Acciones
          if (solicitud.puedeRecibirOCancelar) ...[
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border(
                    top: BorderSide(color: Colors.grey[100]!)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: onCancelar,
                      icon: const Icon(Icons.cancel_outlined,
                          size: 16, color: Color(0xFFF32836)),
                      label: Text('Cancelar',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFF32836))),
                      style: TextButton.styleFrom(
                        padding:
                        const EdgeInsets.symmetric(vertical: 14),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(18)),
                        ),
                      ),
                    ),
                  ),
                  Container(
                      width: 1,
                      height: 44,
                      color: Colors.grey[100]),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: onRecibir,
                      icon: const Icon(Icons.qr_code_rounded,
                          size: 16, color: Color(0xFF00B37E)),
                      label: Text('Recibir',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF00B37E))),
                      style: TextButton.styleFrom(
                        padding:
                        const EdgeInsets.symmetric(vertical: 14),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                              bottomRight: Radius.circular(18)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else
            const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _fmtFecha(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _FilaDetalle extends StatelessWidget {
  final DetalleUniformeModel detalle;
  const _FilaDetalle({required this.detalle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          if (detalle.fotografia.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(detalle.fotografia,
                  width: 36, height: 36, fit: BoxFit.cover),
            )
          else
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.checkroom_outlined,
                  color: Colors.grey, size: 18),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${detalle.talla} · ${detalle.color}',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  'x${detalle.cantidad} · \$${detalle.precioUnitario.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DIALOG QR
// ─────────────────────────────────────────────────────────────────────────────

class _DialogQR extends StatelessWidget {
  final String codigo;
  const _DialogQR({required this.codigo});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Código QR de recepción',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
                'Muestra este código al encargado para confirmar la recepción',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.grey[500]),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: QrImageView(
                data: codigo,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF005DB9).withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                codigo,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF005DB9),
                    letterSpacing: 2),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005DB9),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Cerrar',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGETS AUXILIARES
// ─────────────────────────────────────────────────────────────────────────────

class _BotonCantidad extends StatelessWidget {
  final IconData icono;
  final VoidCallback onTap;
  final bool pequenio;

  const _BotonCantidad(
      {required this.icono,
        required this.onTap,
        this.pequenio = false});

  @override
  Widget build(BuildContext context) {
    final size = pequenio ? 28.0 : 36.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Icon(icono,
            size: pequenio ? 16 : 20,
            color: const Color(0xFF005DB9)),
      ),
    );
  }
}