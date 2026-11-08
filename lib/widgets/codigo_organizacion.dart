import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Estilo monoespaciado del código (SRS 12: JetBrains Mono; si no está
/// instalada se usa la fuente monoespaciada del sistema).
const _estiloCodigo = TextStyle(
  fontFamily: 'JetBrains Mono',
  fontFamilyFallback: ['monospace', 'Courier New', 'Courier'],
  fontWeight: FontWeight.w700,
);

/// Código de acceso de 5 caracteres en casillas individuales (SRS sección 11).
///
/// - Solo lectura: `CodigoOrganizacion(codigo: 'K7Q4X')`.
/// - Captura: `CodigoOrganizacion.captura(controller: ctrl, onCompleto: ...)`.
///   Un único campo invisible recibe el teclado, así el pegado y la
///   accesibilidad funcionan; las casillas solo lo dibujan.
class CodigoOrganizacion extends StatefulWidget {
  const CodigoOrganizacion({super.key, required String this.codigo, this.claro = false})
      : controller = null,
        onCompleto = null,
        error = false;

  const CodigoOrganizacion.captura({
    super.key,
    required TextEditingController this.controller,
    this.onCompleto,
    this.error = false,
  })  : codigo = null,
        claro = false;

  final String? codigo;
  final TextEditingController? controller;
  final ValueChanged<String>? onCompleto;

  /// Casillas para fondo oscuro (Marea).
  final bool claro;
  final bool error;

  static const largo = 5;

  @override
  State<CodigoOrganizacion> createState() => _CodigoOrganizacionState();
}

class _CodigoOrganizacionState extends State<CodigoOrganizacion> {
  final _foco = FocusNode();

  bool get _captura => widget.controller != null;

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_cambio);
    _foco.addListener(_cambio);
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_cambio);
    _foco.dispose();
    super.dispose();
  }

  void _cambio() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final texto = (_captura ? widget.controller!.text : widget.codigo!)
        .toUpperCase();
    final casillas = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < CodigoOrganizacion.largo; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          _Casilla(
            caracter: i < texto.length ? texto[i] : '',
            activa: _captura && _foco.hasFocus && i == texto.length.clamp(0, 4),
            error: widget.error,
            claro: widget.claro,
          ),
        ],
      ],
    );
    if (!_captura) {
      return Semantics(label: 'Código ${texto.split('').join(' ')}', child: casillas);
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _foco.requestFocus,
      child: Stack(alignment: Alignment.center, children: [
        casillas,
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: TextField(
              controller: widget.controller,
              focusNode: _foco,
              autofocus: true,
              maxLength: CodigoOrganizacion.largo,
              enableInteractiveSelection: false,
              showCursor: false,
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              enableSuggestions: false,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                TextInputFormatter.withFunction((_, n) =>
                    n.copyWith(text: n.text.toUpperCase())),
              ],
              decoration: const InputDecoration(counterText: '', border: InputBorder.none),
              onChanged: (v) {
                if (v.length == CodigoOrganizacion.largo) {
                  widget.onCompleto?.call(v.toUpperCase());
                }
              },
            ),
          ),
        ),
      ]),
    );
  }
}

class _Casilla extends StatelessWidget {
  const _Casilla(
      {required this.caracter,
      required this.activa,
      required this.error,
      required this.claro});
  final String caracter;
  final bool activa;
  final bool error;
  final bool claro;

  @override
  Widget build(BuildContext context) {
    final fondo = claro ? Colors.white.withValues(alpha: 0.14) : Colors.white;
    final borde = error
        ? BColors.error
        : activa
            ? BColors.laguna500
            : (claro ? Colors.white54 : BColors.linea);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 48,
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(BRadios.campo),
        border: Border.all(color: borde, width: activa || error ? 2 : 1.5),
      ),
      child: Text(
        caracter,
        style: _estiloCodigo.copyWith(
            fontSize: 26, color: claro ? Colors.white : BColors.tinta),
      ),
    );
  }
}

