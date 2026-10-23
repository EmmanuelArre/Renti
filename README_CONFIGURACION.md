# Renti — configuración, ejecución y pruebas

App Flutter de rentas para estudiantes con tres roles (**arrendador**, **arrendatario/estudiante**, **administrador**).
Backend: **Firebase Auth + Cloud Firestore**. Caché local y modo sin conexión: **SQLite (sqflite)**.

> **Estado de la verificación.** Todo este código se escribió y revisó a mano, pero **no se pudo compilar ni ejecutar** donde se generó (no había SDK de Flutter/Dart ni acceso a pub.dev). Lo único comprobado automáticamente fue que los paréntesis y llaves estén balanceados, que todos los `import` apunten a archivos existentes y que cada `appState.x` usado exista en `AppState`. **`flutter analyze` y `flutter test` están sin ejecutar**: córrelos tú (paso 6) y corrige lo que salga. Es normal que aparezcan algunos errores menores de compilación la primera vez.

---

## 1. Requisitos (macOS)

| Herramienta | Notas |
|---|---|
| Flutter estable (Dart ≥ 3.13.4, ver `pubspec.yaml`) | `flutter doctor` debe salir sin errores |
| Android Studio + Android SDK | emulador con **Google Play** (necesario para Google Sign-In) |
| JDK 17 | el de Android Studio sirve |
| Cuenta de Google | para crear el proyecto de Firebase |
| (opcional) Node + `firebase-tools` | para desplegar reglas desde la terminal |

## 2. Crear el proyecto de Firebase

1. Entra a <https://console.firebase.google.com> → **Agregar proyecto**.
2. **Agregar app → Android**.
   - Nombre del paquete: `com.example.renti` (o el que cambies en `android/app/build.gradle.kts`; deben coincidir).
   - **Huella SHA-1** (obligatoria para Google Sign-In). En macOS:
     ```bash
     keytool -list -v -alias androiddebugkey \
       -keystore ~/.android/debug.keystore -storepass android -keypass android
     ```
     Copia la línea `SHA1:` y pégala en la consola. Para una versión de producción agrega también la SHA-1 de tu keystore de release.
3. Descarga **`google-services.json`** y colócalo en **`android/app/google-services.json`**. *No está incluido en este ZIP a propósito: contiene los datos de tu proyecto.*
4. **Authentication → Método de acceso**: habilita **Correo/contraseña** y **Google** (elige un correo de soporte).
   - Si agregaste la SHA-1 *después* de descargar el JSON, vuelve a descargarlo.
5. **Firestore Database → Crear base de datos** (modo producción; elige una región cercana).
6. Plantilla de correos (opcional): Authentication → Plantillas, para personalizar verificación y recuperación de contraseña.

## 3. Reglas e índices de Firestore

Las reglas están en `firestore.rules`. Puedes pegarlas en *Firestore → Reglas → Publicar*, o por terminal:

```bash
npm i -g firebase-tools
firebase login
firebase use --add          # elige tu proyecto
firebase deploy --only firestore:rules,firestore:indexes
```

No se necesitan índices compuestos (las consultas filtran por igualdad y el orden se hace en el cliente); `firestore.indexes.json` va vacío.

Qué garantizan las reglas:
- Un usuario solo puede **registrarse** como `arrendador` o `arrendatario`, con estado `activo`, y no puede cambiar después su rol, correo ni estado.
- **Administrador = existe el documento `admins/{uid}`.** Ninguna regla permite escribir en `/admins`, así que solo se puede crear desde la consola (paso 4).
- El administrador solo puede cambiar el **estado** de un usuario y la **moderación** de una propiedad.
- Un arrendador solo crea propiedades a su nombre, siempre en `pendiente`, y no puede aprobarlas; cualquier edición vuelve a `pendiente`.
- Un estudiante solo ve propiedades `aprobada`; un arrendamiento solo se crea si la solicitud queda `ACEPTADA` en la misma transacción.
- Chats, notificaciones, solicitudes, arrendamientos y reportes solo son visibles para sus participantes (y el administrador).

## 4. Crear el primer administrador

El administrador **no se puede registrar desde la app**. Para crearlo:

1. Regístrate en la app con el correo que será administrador (elige cualquier rol; da igual).
2. Firebase Console → **Authentication → Usuarios**: copia el **UID** de esa cuenta.
3. **Firestore → Iniciar colección** `admins` → ID de documento = ese **UID**, con un campo cualquiera (p. ej. `activo: true`).
4. Cierra sesión y vuelve a entrar: la app detecta `admins/{uid}` y abre el panel de administración.

> Si esa cuenta ya tenía un documento en `usuarios`, el administrador sigue funcionando: el rol efectivo lo decide la existencia de `admins/{uid}`, no el campo `rol`.

## 5. Android

Ya modificado en el proyecto:

- `AndroidManifest.xml`: permisos `INTERNET` y `ACCESS_NETWORK_STATE`, nombre "Renti". La galería se abre con el selector del sistema (Photo Picker), por lo que **no** hacen falta permisos de almacenamiento.
- `android/app/build.gradle.kts`: plugin `com.google.gms.google-services` y `minSdk = maxOf(flutter.minSdkVersion, 23)`.
- `android/settings.gradle.kts`: declara el plugin `com.google.gms.google-services` versión `4.4.2`.

> El proyecto usa AGP 9.1.0 / Gradle 9.3.1 / Kotlin 2.4.0. La versión `4.4.2` del plugin de Google Services **no se pudo probar** con ese AGP; si Gradle se queja, sube a la versión más reciente publicada del plugin.

## 6. Ejecutar

```bash
cd renti
flutter pub get
flutter analyze            # revisa y corrige lo que reporte
flutter test               # pruebas unitarias y de widget (ver §8)
flutter emulators --launch <id>     # o conecta un teléfono con depuración USB
flutter run
```

Versiones de paquetes: `pubspec.yaml` fija rangos (`firebase_core ^3.15`, `firebase_auth ^5.7`, `cloud_firestore ^5.6`, `google_sign_in ^6.3`, `sqflite ^2.4`, `image_picker ^1.1`, `image ^4.5`, `shared_preferences ^2.5`). Si `pub get` no resuelve, ejecuta `flutter pub upgrade --major-versions` y revisa `flutter analyze`. **`google_sign_in` debe quedarse en 6.x**: la 7.x cambió la API (`GoogleSignIn.instance.authenticate()`), y el código tiene un comentario en `AuthService.iniciarConGoogle` con la variante 7.x.

Para probar **sin conexión**: activa el modo avión después de iniciar sesión y abrir la app una vez; verás el aviso "Sin conexión" y los datos guardados en SQLite.

## 7. Cómo probar cada función

| Función | Cómo probarla |
|---|---|
| Registro con correo | *Crear cuenta* → nombre, correo, contraseña (≥8, mayúscula, minúscula, número) y confirmar. Debe llegar un correo de verificación |
| Verificación de correo | Pantalla "Verifica tu correo" → abre el enlace → *Ya verifiqué* |
| Inicio / persistencia | Inicia sesión, cierra la app por completo y ábrela: entra directo a tu panel |
| Recuperar contraseña | *¿Olvidaste tu contraseña?* → llega el enlace |
| Google Sign-In | Botón de Google. La primera vez pide elegir **rol** (no ofrece administrador) |
| Cuenta duplicada | Registra el mismo correo dos veces → mensaje de que ya existe; si el correo es de Google, el mensaje pide usar ese método |
| Cerrar sesión | Perfil → *Cerrar sesión* (confirma y borra la caché local) |
| Arrendador: publicar | *Propiedades → + Publicar*: 1–4 fotos, tipo, precio, servicios… Queda "En revisión" |
| Arrendador: editar / disponibilidad / eliminar | Botones en cada tarjeta de *Propiedades* |
| Moderación | Entra como administrador → *Propiedades → Pendientes* → abrir → Aprobar / Rechazar / Desactivar (con motivo). El arrendador recibe notificación |
| Estudiante: explorar | Con una propiedad **aprobada**: Inicio, Buscar, filtros, mapa, detalle |
| Favoritos | Corazón (solo estudiantes) → pestaña *Favoritos* |
| Solicitar renta | Detalle → *Reservar* → duración → datos y pago (**simulado**: no cobra nada) → enviar |
| Duplicados | Intenta solicitar la misma propiedad otra vez → se rechaza |
| Responder solicitud | Arrendador → *Solicitudes* → Aceptar (la propiedad pasa a "Rentada" y se rechazan las demás pendientes) o Rechazar |
| Historial / finalizar | Arrendador → *Historial → Finalizar*; el estudiante lo ve en *Rentas* |
| Chat | *Escribir* desde el detalle o una solicitud; se actualiza en tiempo real |
| Reportar | Detalle de propiedad → reportar → el administrador lo resuelve en *Reportes* |
| Usuarios | Administrador → *Usuarios*: filtro por rol, buscar, suspender / reactivar (el suspendido no puede entrar) |
| Estadísticas | Administrador → Panel → *Ver estadísticas detalladas* |
| Tema | Perfil → Configuración → modo claro / oscuro (se recuerda) |

## 8. Pruebas automáticas (`test/`)

- `validators_test.dart`: nombre, correo, contraseña, teléfono, rol (el administrador no es registrable), propiedad, fotos, solicitud.
- `models_test.dart`: ida y vuelta Firestore/SQLite de `AppUser` y `Listing`, visibilidad pública, descuentos por duración, id determinista de solicitudes.
- `database_test.dart`: esquema SQLite en memoria con `sqflite_common_ffi` — las 7 tablas, CRUD, `UNIQUE`, `CHECK`, llaves foráneas y cascada, solicitud activa única, fechas, transacciones y *upsert*.
- `widget_test.dart`: formulario con errores, contraseñas que no coinciden, envío válido y mostrar/ocultar contraseña.

**No se probó con automatización** (requieren Firebase real o dispositivo): Auth, Google Sign-In, lecturas/escrituras en Firestore, reglas de seguridad, selector de fotos, chat y navegación completa. Para las reglas puedes usar el *Simulador de reglas* de la consola o el emulador de Firebase.

## 9. Estructura

```
lib/
  main.dart, app/            arranque, MaterialApp, rutas con guardas por rol
  core/
    constants/               roles, estados, catálogos, límites
    validators/              validadores puros reutilizados por formularios y lógica
    database/                SQLite: esquema, restricciones, upsert
    services/                auth, imágenes, patrón remoto-o-local
    state/app_state.dart     estado global (fachada sobre los repositorios)
    theme/, widgets/         Material 3 claro/oscuro y componentes reutilizables
  models/                    AppUser, Listing, Rental/RentalRequest, Report, Chat…
  repositories/              Firestore + caché SQLite por entidad
  features/
    auth/                    splash, bienvenida, login, registro, recuperar, verificar, rol
    arrendatario/            inicio, buscar, filtros, resultados, mapa, solicitud, pago, rentas
    arrendador/              panel, mis propiedades, publicar/editar, solicitudes, historial
    administrador/           panel, usuarios, propiedades (moderación), reportes, estadísticas
    perfil/                  perfil, editar, notificaciones, configuración
  shared/                    detalle de propiedad, chat, mensajes, reportar
firestore.rules, firestore.indexes.json, firebase.json
test/
```

## 10. Qué cambió respecto a la app original

- **Datos:** se eliminó `MockData`; todo viene de Firestore con caché en SQLite (7 tablas con PK, FK, `CHECK`, índices y transacciones).
- **Roles y rutas:** tres roles con `RoleGuard` en cada ruta y menú inferior por rol; el rol se valida en el servidor con las reglas.
- **Autenticación:** correo/contraseña (registro, login, recuperación, verificación, sesión persistente, cierre) y Google; sin contraseñas propias en ninguna base.
- **Arrendador:** panel, propiedades con fotos reales (hasta 4, base64 reducido), edición, disponibilidad, solicitudes con aceptar/rechazar, historial.
- **Estudiante:** búsqueda y filtros sobre datos reales, favoritos, solicitudes (sin duplicados), rentas, pagos simulados, chat.
- **Administrador (nuevo):** panel, usuarios, moderación, reportes, estadísticas.
- **Validaciones:** formulario, reglas de negocio (`Validators`, repositorios) y base de datos (`CHECK`/`UNIQUE`/`FK`).
- **Estados de interfaz:** carga, vacío, error con reintento, banner sin conexión y confirmaciones de acciones destructivas.
- Se **conservaron** la identidad visual, las pantallas existentes (pago, chat, mapa, duración) y sus nombres.

## 11. Limitaciones conocidas (sé honesto con tu profesor)

- **Sin compilar ni ejecutar** (ver el aviso al inicio).
- **Pagos simulados**: no hay pasarela real.
- **Mapa ilustrativo**: no usa Google Maps; los pines se colocan sobre un fondo dibujado.
- **Fotos en base64 dentro de Firestore** (documento ≤ 1 MiB; por eso se reducen a 1024 px y máx. 4). Para producción lo correcto es Firebase Storage (requiere plan Blaze).
- **Notificaciones**: se guardan y se muestran dentro de la app; no hay push (FCM).
- **Calificaciones**: el campo existe, pero no hay pantalla para calificar.
- El administrador no puede ver el contenido de los chats (por privacidad), solo reportes.
- El *rate limiting* y la prevención de abuso (spam de solicitudes o notificaciones) no están implementados más allá de las reglas.
