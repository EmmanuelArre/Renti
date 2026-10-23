import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import 'package:renti/core/constants/app_constants.dart';
import 'package:renti/core/validators/validators.dart';

/// Foto lista para guardar: imagen completa y miniatura, ambas en base64.
class FotoPropiedad {
  final String nombre;
  final String datos; // base64 de la imagen (máx. ~1024 px)
  const FotoPropiedad(this.nombre, this.datos);
}

/// Selección, validación y compresión de fotografías.
///
/// Las imágenes se guardan en base64 dentro de Firestore/SQLite para no
/// depender de Firebase Storage (que exige plan de pago). Por eso se reducen
/// a 1024 px y calidad 70 antes de guardarlas.
class ImageService {
  ImageService._();
  static final ImageService instance = ImageService._();

  final ImagePicker _picker = ImagePicker();

  /// Abre la galería. Devuelve las fotos válidas y lanza [RentiException] si
  /// alguna tiene formato o tamaño no admitido.
  Future<List<FotoPropiedad>> elegirFotos({required int maximo}) async {
    if (maximo <= 0) {
      throw const RentiException('Ya alcanzaste el máximo de fotografías.');
    }
    final List<XFile> archivos;
    if (maximo == 1) {
      // pickMultiImage exige limit >= 2, por eso el caso de 1 foto es aparte.
      final una = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70,
      );
      archivos = una == null ? <XFile>[] : <XFile>[una];
    } else {
      archivos = await _picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70,
        limit: maximo,
      );
    }
    final resultado = <FotoPropiedad>[];
    for (final a in archivos.take(maximo)) {
      final bytes = await a.readAsBytes();
      final error = Validators.foto(nombre: a.name, bytes: bytes.length);
      if (error != null) throw RentiException(error);
      resultado.add(FotoPropiedad(a.name, base64Encode(bytes)));
    }
    return resultado;
  }

  /// Foto de perfil o miniatura de portada (480 px de ancho, JPG calidad 60).
  String miniatura(String base64Imagen) {
    final bytes = base64Decode(base64Imagen);
    final original = img.decodeImage(Uint8List.fromList(bytes));
    if (original == null) return base64Imagen;
    final reducida = original.width > 480
        ? img.copyResize(original, width: 480)
        : original;
    return base64Encode(img.encodeJpg(reducida, quality: 60));
  }

  static String? validarCantidad(int total) => Validators.cantidadFotos(total);

  static int get maximo => Limites.maxFotos;
}
