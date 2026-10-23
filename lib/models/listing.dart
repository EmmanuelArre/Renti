import 'dart:convert';

import 'package:renti/core/constants/app_constants.dart';
import 'package:renti/models/model_utils.dart';

enum ListingStatus { disponible, rentado }

class DurationOption {
  final String label; // "1 mes"
  final int months; // 0 = indefinido
  final int pricePerMonth;
  final int savingsPercent;
  const DurationOption(
      this.label, this.months, this.pricePerMonth, this.savingsPercent);
}

/// Propiedad en renta. Documento `propiedades/{id}` en Firestore y fila en la
/// tabla `propiedades` de SQLite. Las fotografías completas viven aparte
/// (`propiedades/{id}/imagenes` y tabla `imagenes_propiedad`); aquí solo se
/// guarda la miniatura de portada en base64.
class Listing {
  final String id;
  final String ownerId;
  final String title;
  final String type; // Habitación, Departamento, Casa, Compartido
  final String address;
  final String distance; // ubicación / referencia: "A 800 m de la universidad"
  final int price;
  final double? rating;
  final int reviews;
  final String description;
  final int bedrooms;
  final int bathrooms;
  final bool shared;
  final List<String> services;
  final String landlord; // nombre del arrendador
  final ListingStatus status;
  final String moderation; // ver [Moderacion]
  final String? cover; // miniatura JPG en base64
  final DateTime createdAt;
  final DateTime updatedAt;

  Listing({
    required this.id,
    this.ownerId = '',
    required this.title,
    required this.type,
    required this.address,
    required this.distance,
    required this.price,
    this.rating,
    this.reviews = 0,
    this.description = '',
    this.bedrooms = 1,
    this.bathrooms = 1,
    this.shared = false,
    this.services = const [],
    this.landlord = '',
    this.status = ListingStatus.disponible,
    this.moderation = Moderacion.pendiente,
    this.cover,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isAvailable => status == ListingStatus.disponible;
  bool get isApproved => moderation == Moderacion.aprobada;

  /// Visible para estudiantes: aprobada por el administrador y disponible.
  bool get isPublic => isApproved && isAvailable;

  String get publishedAgo {
    final days = DateTime.now().difference(createdAt).inDays;
    if (days <= 0) return 'Publicado hoy';
    if (days == 1) return 'Publicado ayer';
    if (days < 14) return 'Publicado hace $days días';
    final weeks = days ~/ 7;
    if (weeks < 8) return 'Publicado hace $weeks semanas';
    return 'Publicado el ${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  Listing copyWith({
    String? title,
    String? type,
    String? address,
    String? distance,
    int? price,
    String? description,
    int? bedrooms,
    int? bathrooms,
    bool? shared,
    List<String>? services,
    ListingStatus? status,
    String? moderation,
    String? cover,
    DateTime? updatedAt,
  }) =>
      Listing(
        id: id,
        ownerId: ownerId,
        title: title ?? this.title,
        type: type ?? this.type,
        address: address ?? this.address,
        distance: distance ?? this.distance,
        price: price ?? this.price,
        rating: rating,
        reviews: reviews,
        description: description ?? this.description,
        bedrooms: bedrooms ?? this.bedrooms,
        bathrooms: bathrooms ?? this.bathrooms,
        shared: shared ?? this.shared,
        services: services ?? this.services,
        landlord: landlord,
        status: status ?? this.status,
        moderation: moderation ?? this.moderation,
        cover: cover ?? this.cover,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );

  /// Opciones de duración con descuentos (1 mes = precio base, 3 meses -6 %,
  /// 6 meses -11 %, indefinido -14 %).
  List<DurationOption> get durations {
    int p(int pct) => (price * (100 - pct) / 100 / 100).round() * 100;
    return [
      DurationOption('1 mes', 1, price, 0),
      DurationOption('3 meses', 3, p(6), 6),
      DurationOption('6 meses', 6, p(11), 11),
      DurationOption('Indefinido', 0, p(14), 14),
    ];
  }

  /// Mapa para Firestore (listas nativas).
  Map<String, Object?> toMap() => {
        'propietarioId': ownerId,
        'propietarioNombre': landlord,
        'titulo': title,
        'tipo': type,
        'direccion': address,
        'referencia': distance,
        'precio': price,
        'descripcion': description,
        'habitaciones': bedrooms,
        'banos': bathrooms,
        'compartido': shared,
        'servicios': services,
        'estado': status.name,
        'moderacion': moderation,
        'portada': cover ?? '',
        'creadoEn': iso(createdAt),
        'actualizadoEn': iso(updatedAt),
      };

  /// Fila para SQLite (listas como JSON, booleanos como 0/1).
  Map<String, Object?> toRow() => {
        'id': id,
        'propietario_id': ownerId,
        'propietario_nombre': landlord,
        'titulo': title,
        'tipo': type,
        'direccion': address,
        'referencia': distance,
        'precio': price,
        'descripcion': description,
        'habitaciones': bedrooms,
        'banos': bathrooms,
        'compartido': shared ? 1 : 0,
        'servicios': jsonEncode(services),
        'estado': status.name,
        'moderacion': moderation,
        'portada': cover ?? '',
        'rating': rating,
        'resenas': reviews,
        'creado_en': iso(createdAt),
        'actualizado_en': iso(updatedAt),
      };

  /// Acepta tanto un documento de Firestore como una fila de SQLite.
  factory Listing.fromMap(Map<String, Object?> m, {String? id}) {
    final portada = asString(m['portada']);
    return Listing(
      id: id ?? asString(m['id']),
      ownerId: asString(m['propietarioId'] ?? m['propietario_id']),
      landlord: asString(m['propietarioNombre'] ?? m['propietario_nombre']),
      title: asString(m['titulo']),
      type: asString(m['tipo']),
      address: asString(m['direccion']),
      distance: asString(m['referencia']),
      price: asInt(m['precio']),
      rating: asDoubleOrNull(m['rating']),
      reviews: asInt(m['resenas']),
      description: asString(m['descripcion']),
      bedrooms: asInt(m['habitaciones'], 1),
      bathrooms: asInt(m['banos'], 1),
      shared: asBool(m['compartido']),
      services: asStringList(m['servicios']),
      status: asString(m['estado']) == ListingStatus.rentado.name
          ? ListingStatus.rentado
          : ListingStatus.disponible,
      moderation: asString(m['moderacion'], Moderacion.pendiente),
      cover: portada.isEmpty ? null : portada,
      createdAt: asDate(m['creadoEn'] ?? m['creado_en']),
      updatedAt: asDate(m['actualizadoEn'] ?? m['actualizado_en']),
    );
  }
}
