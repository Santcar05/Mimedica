import 'package:flutter/material.dart';

import '../../app/tema.dart';
import '../../nucleo/widgets/filas.dart';

enum Legal {
  terminos('Términos del servicio', [
    (
      'Qué hace Mimedica',
      'Calcula cuándo se acaba cada medicamento a partir de los datos que '
          'registras y, diez días antes, te avisa y te muestra las opciones '
          'que el equipo logró verificar para conseguirlo.',
    ),
    (
      'Qué no hace',
      'No reemplaza a tu médico ni a tu EPS, no vende medicamentos y no '
          'garantiza que el medicamento esté disponible. Las fechas son una '
          'proyección: dependen de que los datos que escribes sean correctos.',
    ),
    (
      'Versión de prueba',
      'Esta es una versión piloto y gratuita. Puede tener errores. Si algo no '
          'coincide con lo que dijo tu médico, sigue siempre la fórmula.',
    ),
    (
      'Tu cuenta',
      'Puedes cerrar la sesión o eliminar la cuenta con todos sus datos '
          'cuando quieras, desde Cuenta.',
    ),
  ]),
  datos('Política de datos', [
    (
      'Qué guardamos',
      'Tu nombre, documento, fecha de nacimiento y correo; el nombre de la '
          'persona que cuidas; sus medicamentos, dosis y entregas; y la foto '
          'de la fórmula que subes.',
    ),
    (
      'Para qué',
      'Para calcular fechas de agotamiento, consultar la disponibilidad con '
          'tu EPS y con droguerías, y avisarte. Los datos de salud son datos '
          'sensibles según la Ley 1581 de 2012: solo los tratamos con tu '
          'autorización expresa.',
    ),
    (
      'Dónde están',
      'En servidores de Supabase fuera de Colombia, protegidos para que cada '
          'hogar vea solo lo suyo. Al autorizar aceptas esa transmisión '
          'internacional.',
    ),
    (
      'Con quién los compartimos',
      'Solo con tu EPS y con la droguería que tú elijas. No los vendemos ni '
          'los usamos para publicidad.',
    ),
    (
      'Tus derechos',
      'Puedes conocer, corregir y eliminar tus datos, y revocar la '
          'autorización, en Cuenta › Privacidad y datos.',
    ),
  ]);

  const Legal(this.titulo, this.secciones);
  final String titulo;
  final List<(String, String)> secciones;
}

Future<void> abrirDocumento(BuildContext context, Legal documento) {
  return abrirHoja(
    context,
    constructor: (context) => ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.7,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(documento.titulo, style: Letra.titulo),
            for (final (titulo, texto) in documento.secciones) ...[
              const SizedBox(height: 20),
              Text(titulo, style: Letra.cuerpoFuerte),
              const SizedBox(height: 4),
              Text(texto, style: Letra.cuerpo.copyWith(color: Tinta.suave)),
            ],
          ],
        ),
      ),
    ),
  );
}
