/// Topes de lo que una persona puede escribir. Una fórmula crónica rara vez
/// pasa de seis meses de tabletas, así que 999 deja margen de sobra y evita
/// fechas imposibles por un cero de más.
abstract final class Limites {
  /// Unidades por toma.
  static const porToma = 20.0;

  /// Unidades en casa, recibidas en una entrega o que faltaron.
  static const cantidad = 999.0;

  /// Días máximos que se proyectan hacia adelante (diez años).
  static const diasProyectados = 3650;
}
