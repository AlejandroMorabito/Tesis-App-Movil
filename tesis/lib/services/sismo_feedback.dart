import 'package:flutter/material.dart';

/// Notificación tipo "toast" que aparece ARRIBA de la pantalla.
/// Si ya hay una visible la reemplaza (ideal para el flujo "procesando…" → "listo").
class SismoFeedback {
  static OverlayEntry? _current;

  static void show(
    BuildContext context,
    String message, {
    Color color = const Color(0xFF0EA5E9),
    Duration duration = const Duration(seconds: 2),
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    // Quitar la anterior si sigue en pantalla
    _current?.remove();
    _current = null;

    final entry = OverlayEntry(
      builder: (ctx) {
        final topInset = MediaQuery.of(ctx).padding.top;
        return Positioned(
          top: topInset + 12,
          left: 16,
          right: 16,
          child: IgnorePointer(
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2736),
                  borderRadius: BorderRadius.circular(12),
                  border: Border(left: BorderSide(color: color, width: 4)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFFE2E8F0),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    _current = entry;
    overlay.insert(entry);

    Future.delayed(duration, () {
      // Solo quitarla si sigue siendo la actual (si otra la reemplazó, ya se removió)
      if (_current == entry) {
        entry.remove();
        _current = null;
      }
    });
  }
}
