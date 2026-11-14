import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/tema.dart';

/// Seis casillas sobre un único campo de texto: admite pegar el código
/// y el autocompletado del teclado.
class CasillasCodigo extends StatefulWidget {
  const CasillasCodigo({
    super.key,
    required this.controlador,
    required this.alCompletar,
    this.conError = false,
    this.habilitado = true,
  });

  static const largo = 6;

  final TextEditingController controlador;
  final ValueChanged<String> alCompletar;
  final bool conError;
  final bool habilitado;

  @override
  State<CasillasCodigo> createState() => _CasillasCodigoState();
}

class _CasillasCodigoState extends State<CasillasCodigo> {
  final _foco = FocusNode();

  @override
  void initState() {
    super.initState();
    _foco.addListener(_repintar);
    widget.controlador.addListener(_repintar);
  }

  @override
  void dispose() {
    widget.controlador.removeListener(_repintar);
    _foco.dispose();
    super.dispose();
  }

  void _repintar() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final codigo = widget.controlador.text;
    return Semantics(
      label: 'Código de 6 dígitos',
      textField: true,
      value: codigo,
      child: Stack(
        children: [
          Row(
            children: [
              for (var i = 0; i < CasillasCodigo.largo; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _Casilla(
                    digito: i < codigo.length ? codigo[i] : '',
                    actual: _foco.hasFocus && i == codigo.length,
                    conError: widget.conError,
                  ),
                ),
              ],
            ],
          ),
          Positioned.fill(
            child: ExcludeSemantics(
              child: TextField(
                controller: widget.controlador,
                focusNode: _foco,
                autofocus: true,
                enabled: widget.habilitado,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(CasillasCodigo.largo),
                ],
                showCursor: false,
                enableInteractiveSelection: false,
                style: const TextStyle(color: Colors.transparent, fontSize: 1),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  counterText: '',
                ),
                onChanged: (valor) {
                  if (valor.length == CasillasCodigo.largo) {
                    widget.alCompletar(valor);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Casilla extends StatelessWidget {
  const _Casilla({
    required this.digito,
    required this.actual,
    required this.conError,
  });

  final String digito;
  final bool actual;
  final bool conError;

  @override
  Widget build(BuildContext context) {
    final color = conError
        ? Tinta.riesgo
        : actual
        ? Tinta.azul
        : Tinta.tenue;
    return AnimatedContainer(
      duration: Ritmo.micro,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Tinta.papel,
        borderRadius: radio,
        border: Border.all(color: color, width: actual || conError ? 2 : 1),
      ),
      child: Text(
        digito,
        style: Letra.titulo.tabular.copyWith(
          color: conError ? Tinta.riesgo : Tinta.tinta,
        ),
      ),
    );
  }
}
