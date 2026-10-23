import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:renti/core/constants/app_constants.dart';
import 'package:renti/core/services/image_service.dart';
import 'package:renti/core/state/app_state.dart';
import 'package:renti/core/theme/app_theme.dart';
import 'package:renti/core/validators/validators.dart';
import 'package:renti/core/widgets/buttons.dart';
import 'package:renti/core/widgets/common_widgets.dart';
import 'package:renti/core/widgets/form_widgets.dart';
import 'package:renti/core/widgets/listing_widgets.dart';
import 'package:renti/models/listing.dart';
import 'package:renti/repositories/property_repository.dart';

/// 23 · Publicar propiedad (o editar una existente si se pasa [editing]).
///
/// Toda publicación nueva o editada queda "pendiente" hasta que el
/// administrador la apruebe.
class PublishScreen extends StatefulWidget {
  final Listing? editing;
  const PublishScreen({super.key, this.editing});

  @override
  State<PublishScreen> createState() => _PublishScreenState();
}

class _PublishScreenState extends State<PublishScreen> {
  final _form = GlobalKey<FormState>();
  late final _titulo = TextEditingController(text: widget.editing?.title);
  late final _direccion = TextEditingController(text: widget.editing?.address);
  late final _referencia =
      TextEditingController(text: widget.editing?.distance);
  late final _precio = TextEditingController(
      text: widget.editing == null ? '' : '${widget.editing!.price}');
  late final _descripcion =
      TextEditingController(text: widget.editing?.description);
  late final _habitaciones = TextEditingController(
      text: widget.editing == null ? '1' : '${widget.editing!.bedrooms}');
  late final _banos = TextEditingController(
      text: widget.editing == null ? '1' : '${widget.editing!.bathrooms}');

  late String? _tipo = widget.editing?.type;
  late final Set<String> _servicios = {...?widget.editing?.services};

  /// Fotos en base64 que se muestran (existentes o recién elegidas).
  List<String> _fotos = [];
  List<FotoPropiedad> _nuevas = [];
  bool _fotosCambiadas = false;
  bool _cargandoFotos = false;
  bool _guardando = false;

  bool _intentoEnvio = false;

  bool get _editando => widget.editing != null;

  @override
  void initState() {
    super.initState();
    if (_editando) _cargarFotosExistentes();
  }

  @override
  void dispose() {
    for (final c in [
      _titulo,
      _direccion,
      _referencia,
      _precio,
      _descripcion,
      _habitaciones,
      _banos,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _cargarFotosExistentes() async {
    setState(() => _cargandoFotos = true);
    final fotos = await PropertyRepository.instance.imagenes(widget.editing!.id);
    if (!mounted) return;
    setState(() {
      _fotos = fotos;
      _cargandoFotos = false;
    });
  }

  Future<void> _agregarFotos() async {
    final restantes = Limites.maxFotos - _fotos.length;
    try {
      final nuevas = await ImageService.instance.elegirFotos(maximo: restantes);
      if (nuevas.isEmpty || !mounted) return;
      setState(() {
        // Al tocar las fotos de una propiedad existente se reemplaza el
        // conjunto completo, así que se parte de lo que ya se muestra.
        if (!_fotosCambiadas) {
          _nuevas = [
            for (var i = 0; i < _fotos.length; i++)
              FotoPropiedad('foto_${i + 1}.jpg', _fotos[i]),
          ];
        }
        _nuevas = [..._nuevas, ...nuevas];
        _fotos = _nuevas.map((f) => f.datos).toList();
        _fotosCambiadas = true;
      });
    } on RentiException catch (e) {
      if (mounted) showSnack(context, e.message);
    } catch (_) {
      if (mounted) showSnack(context, 'No se pudo abrir la galería.');
    }
  }

  void _quitarFoto(int i) {
    setState(() {
      if (!_fotosCambiadas) {
        _nuevas = [
          for (var k = 0; k < _fotos.length; k++)
            FotoPropiedad('foto_${k + 1}.jpg', _fotos[k]),
        ];
      }
      _nuevas = [..._nuevas]..removeAt(i);
      _fotos = _nuevas.map((f) => f.datos).toList();
      _fotosCambiadas = true;
    });
  }

  String? get _errorFotos =>
      _intentoEnvio ? Validators.cantidadFotos(_fotos.length) : null;

  String? get _errorTipo => _intentoEnvio ? Validators.tipoPropiedad(_tipo) : null;

  String? get _errorServicios => _intentoEnvio
      ? Validators.serviciosSeleccionados(_servicios)
      : null;

  Future<void> _guardar() async {
    setState(() => _intentoEnvio = true);
    final formOk = _form.currentState?.validate() ?? false;
    final extraOk = _errorFotos == null &&
        _errorTipo == null &&
        _errorServicios == null;
    if (!formOk || !extraOk) {
      showSnack(context, 'Revisa los campos marcados en rojo.');
      return;
    }
    final datos = DatosPropiedad(
      titulo: _titulo.text,
      tipo: _tipo!,
      direccion: _direccion.text,
      referencia: _referencia.text,
      precio: _precio.text,
      descripcion: _descripcion.text,
      habitaciones: _habitaciones.text,
      banos: _banos.text,
      servicios: _servicios.toList(),
    );
    setState(() => _guardando = true);
    final String? error;
    if (_editando) {
      error = await appState.editarPropiedad(
        widget.editing!,
        datos,
        _fotosCambiadas ? _nuevas : null,
      );
    } else {
      error = await appState.crearPropiedad(datos, _nuevas);
    }
    if (!mounted) return;
    setState(() => _guardando = false);
    if (error != null) {
      showSnack(context, error);
      return;
    }
    Navigator.of(context).pop();
    showSnack(
      context,
      _editando
          ? 'Cambios guardados. La publicación se enviará a revisión.'
          : 'Propiedad enviada a revisión del administrador.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: ScreenHeader(
                  title: _editando ? 'Editar propiedad' : 'Publicar propiedad'),
            ),
            Expanded(
              child: Form(
                key: _form,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  children: [
                    _fotosSection(context),
                    RentiTextField(
                      label: 'Nombre de la propiedad',
                      hint: 'Ej. Cuarto cerca de la UTNG',
                      controller: _titulo,
                      maxLength: 60,
                      textCapitalization: TextCapitalization.sentences,
                      validator: Validators.tituloPropiedad,
                    ),
                    const SizedBox(height: 4),
                    SelectField(
                      label: 'Tipo de propiedad',
                      hint: 'Selecciona un tipo',
                      value: _tipo,
                      options: Catalogos.tiposPropiedad,
                      errorText: _errorTipo,
                      onChanged: (v) => setState(() => _tipo = v),
                    ),
                    const SizedBox(height: 4),
                    RentiTextField(
                      label: 'Dirección',
                      hint: 'Calle, número y colonia',
                      controller: _direccion,
                      maxLength: 120,
                      textCapitalization: TextCapitalization.words,
                      validator: Validators.direccion,
                    ),
                    const SizedBox(height: 4),
                    RentiTextField(
                      label: 'Ubicación / referencia',
                      hint: 'Ej. A 800 m de la universidad',
                      controller: _referencia,
                      maxLength: 80,
                      validator: Validators.ubicacion,
                    ),
                    const SizedBox(height: 4),
                    RentiTextField(
                      label: 'Precio mensual (MXN)',
                      hint: 'Ej. 2500',
                      controller: _precio,
                      keyboardType: TextInputType.number,
                      maxLength: 7,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: Validators.precio,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: RentiTextField(
                            label: 'Habitaciones',
                            hint: '1',
                            controller: _habitaciones,
                            keyboardType: TextInputType.number,
                            maxLength: 2,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            validator: (v) => Validators.enteroEnRango(
                                v, 'Habitaciones', 0, 20),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: RentiTextField(
                            label: 'Baños',
                            hint: '1',
                            controller: _banos,
                            keyboardType: TextInputType.number,
                            maxLength: 2,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            validator: (v) =>
                                Validators.enteroEnRango(v, 'Baños', 1, 20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    RentiTextField(
                      label: 'Descripción',
                      hint: 'Cuéntales cómo es el lugar, reglas, qué incluye…',
                      controller: _descripcion,
                      maxLines: 5,
                      maxLength: 600,
                      textCapitalization: TextCapitalization.sentences,
                      validator: Validators.descripcion,
                    ),
                    const FieldLabel('Servicios incluidos'),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final s in Catalogos.servicios)
                          PillChip(
                            label: s,
                            selected: _servicios.contains(s),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            onTap: () => setState(() {
                              _servicios.contains(s)
                                  ? _servicios.remove(s)
                                  : _servicios.add(s);
                            }),
                          ),
                      ],
                    ),
                    if (_errorServicios != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 6, 0, 0),
                        child: Text(
                          _errorServicios!,
                          style: const TextStyle(
                              color: Colors.redAccent, fontSize: 13),
                        ),
                      ),
                    const SizedBox(height: 14),
                    Text(
                      'Tu publicación será revisada por un administrador antes '
                      'de aparecer para los estudiantes.',
                      style: TextStyle(color: context.muted, fontSize: 13.5),
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: _editando ? 'Guardar cambios' : 'Publicar',
                      loading: _guardando,
                      onPressed: _guardando ? null : _guardar,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fotosSection(BuildContext context) {
    final error = _errorFotos;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel('Fotografías (${_fotos.length}/${Limites.maxFotos})'),
        if (_cargandoFotos)
          const SizedBox(
            height: 96,
            child: Center(child: CircularProgressIndicator()),
          )
        else
          SizedBox(
            height: 96,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (var i = 0; i < _fotos.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Stack(
                      children: [
                        ListingImage(
                          width: 96,
                          height: 96,
                          radius: BorderRadius.circular(16),
                          photo: _fotos[i],
                        ),
                        Positioned(
                          right: 4,
                          top: 4,
                          child: GestureDetector(
                            onTap: _guardando ? null : () => _quitarFoto(i),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded,
                                  size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_fotos.length < Limites.maxFotos)
                  GestureDetector(
                    onTap: _guardando ? null : _agregarFotos,
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: context.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: error == null ? context.line : Colors.redAccent,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_a_photo_outlined,
                              color: RentiColors.blue),
                          const SizedBox(height: 4),
                          Text('Agregar',
                              style: TextStyle(
                                  color: context.muted, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 0, 0),
            child: Text(error,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
          ),
      ],
    );
  }
}
