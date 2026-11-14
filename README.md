# Mimedica

App móvil para cuidadores que gestionan el tratamiento crónico de un familiar.
Calcula cuándo se acaba cada medicamento y empieza a gestionarlo diez días antes.

Flutter · Supabase · Android (APK) · iOS (compilable desde macOS)

## Qué incluye esta versión

| Bloque | Pantallas |
|---|---|
| Activación | Bienvenida, ingreso con código al correo, datos básicos, consentimiento, para quién, foto de la fórmula, plan y plan activo |
| Uso diario | Inicio por urgencia, detalle del tratamiento, editar el plan, agregar tratamiento, marcar entrega recibida |
| Ciclo de reposición | Seguimiento del ciclo, opciones verificadas, «ya lo conseguí», pendientes de la EPS |
| Cuenta | Privacidad, avisos, ayuda, cerrar sesión, eliminar cuenta y datos |

Lo que el equipo hace a mano en esta versión: consultar a la EPS y a las droguerías, y cargar
las opciones de cada ciclo desde el panel de Supabase. El aviso del día D-10 es una
notificación programada en el teléfono.

## Requisitos

- Flutter 3.32 o superior (Dart 3.8)
- Android SDK para generar el APK
- Un proyecto de Supabase (plan gratuito)

## Puesta en marcha

```bash
flutter pub get
flutter test
flutter run
```

Sin llaves de Supabase la app guarda todo en el teléfono y el ingreso es de prueba:
cualquier correo entra con el código `123456`. Sirve para revisar las pantallas.

### Conectar Supabase

1. Crea un proyecto en [supabase.com](https://supabase.com).
2. En el editor SQL ejecuta [supabase/migrations/0001_esquema.sql](supabase/migrations/0001_esquema.sql).
   Crea las tablas, las políticas RLS, el bucket privado `formulas` y la función `eliminar_cuenta`.
3. En *Authentication › Email* deja activado el ingreso por correo y cambia la plantilla
   *Magic Link* por una que muestre el código: `Tu código de Mimedica es {{ .Token }}`.
4. Copia `env.ejemplo.json` a `env.json` y pega la URL y la clave pública del proyecto.
   El archivo `env.json` no se versiona.

```bash
flutter run --dart-define-from-file=env.json
```

También se puede definir `SOPORTE_CORREO` en ese archivo para mostrar un contacto en *Ayuda y soporte*.

### Cargar las opciones de un ciclo

Cuando se abre un ciclo aparece en la vista `ciclos_por_gestionar`. Para responder al cuidador:

- Escribe lo que averiguaste con la EPS en `ciclos.nota`.
- Inserta filas en `opciones` (EPS o droguería, precio, distancia, teléfono).
- Para marcar la entrega como asegurada, cambia `ciclos.estado` a `asegurado`.

## Medir el tiempo hasta el primer valor

La app registra eventos en la tabla `eventos` (`autorizacion`, `plan_activado`, `ciclo_abierto`, `entrega`).
Minutos desde que la persona creó su cuenta hasta que vio la fecha de agotamiento:

```sql
select
  u.email,
  round(extract(epoch from (min(e.ocurrio_el) - u.created_at)) / 60, 1) as minutos_hasta_el_primer_valor
from auth.users u
join public.eventos e on e.usuario_id = u.id and e.nombre = 'plan_activado'
group by u.id, u.email, u.created_at
order by u.created_at;
```

## Generar el APK

```bash
flutter build apk --release --dart-define-from-file=env.json
```

El APK queda en `build/app/outputs/flutter-apk/app-release.apk`.

Se firma con `android/key.properties` y `android/mimedica-firma.jks`, que no se versionan.
Guarda una copia de ambos archivos: sin ellos no se pueden publicar actualizaciones de la misma app.
Si no existen, el build usa la llave de depuración.

Para iPhone hace falta un Mac con Xcode y una cuenta de Apple Developer:
`flutter build ipa --dart-define-from-file=env.json`.

## Estructura

```
lib/
  app/          tema, rutas y entorno
  datos/        modelos, cálculo de agotamiento, repositorios y avisos
  nucleo/       componentes de interfaz compartidos
  funciones/    una carpeta por flujo (ingreso, activación, fórmula, inicio, ciclo…)
supabase/       esquema de la base de datos
test/           pruebas del cálculo, del estado del hogar y de las entradas
```

## Flujo de ramas

Se trabaja con git flow: `main` solo recibe versiones etiquetadas, `develop` integra, y cada
funcionalidad vive en su rama `feature/*`.
