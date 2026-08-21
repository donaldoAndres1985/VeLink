import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database.dart';
import '../../core/preferences/preferences_provider.dart';
import '../../core/theme/app_theme.dart';
import 'link_card.dart';

class SwipeableLinkCard extends ConsumerStatefulWidget {
  final Link link;

  const SwipeableLinkCard({super.key, required this.link});

  @override
  ConsumerState<SwipeableLinkCard> createState() => _SwipeableLinkCardState();
}

class _SwipeableLinkCardState extends ConsumerState<SwipeableLinkCard>
    with SingleTickerProviderStateMixin {
  double _offset = 0.0;
  bool _committing = false;
  // Oculta la card inmediatamente tras el dismiss de eliminación para
  // evitar que el fondo rojo quede visible mientras la BD actualiza.
  bool _hidden = false;

  late AnimationController _animCtrl;
  late Animation<double> _anim;

  static const _kThreshold = 0.35;
  static const _kDismissMs = 220;
  static const _kSnapMs = 420;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: _kSnapMs))
      ..addListener(() {
        if (mounted) setState(() => _offset = _anim.value);
      });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  /// Anima el offset desde su valor actual hasta [target].
  Future<void> _runAnim(
    double target, {
    int ms = _kSnapMs,
    Curve curve = Curves.easeOutBack,
  }) {
    _animCtrl.stop();
    _animCtrl.duration = Duration(milliseconds: ms);
    _anim = Tween<double>(begin: _offset, end: target)
        .animate(CurvedAnimation(parent: _animCtrl, curve: curve));
    return _animCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    // Tras el dismiss de eliminación la card se convierte en SizedBox vacío
    // para que la fila colapse y no quede el fondo rojo visible.
    if (_hidden) return const SizedBox.shrink();

    final showDelete = _offset > 20;
    final showReviewed = _offset < -20;
    // Durante el dismiss se permite salir del clamp visual para el efecto de salida.
    final visualOffset = _committing ? _offset : _offset.clamp(-220.0, 220.0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragUpdate: _committing
          ? null
          : (d) => setState(() => _offset += d.delta.dx),
      onHorizontalDragEnd: _committing ? null : _onDragEnd,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Fondo eliminar (swipe derecha)
          Positioned.fill(
            child: Opacity(
              opacity: showDelete ? 1.0 : 0.0,
              child: Container(
                decoration: BoxDecoration(
                  color: VerLinkColors.error.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 20),
                child: const Icon(Icons.delete_rounded, color: VerLinkColors.error, size: 24),
              ),
            ),
          ),
          // Fondo revisado (swipe izquierda)
          Positioned.fill(
            child: Opacity(
              opacity: showReviewed ? 1.0 : 0.0,
              child: Container(
                decoration: BoxDecoration(
                  color: VerLinkColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.check_circle_rounded, color: VerLinkColors.primary, size: 24),
              ),
            ),
          ),
          // Card deslizable
          Transform.translate(
            offset: Offset(visualOffset, 0),
            child: LinkCard(link: widget.link),
          ),
        ],
      ),
    );
  }

  void _onDragEnd(DragEndDetails details) {
    final sw = MediaQuery.of(context).size.width;
    final ratio = _offset.abs() / sw;

    if (ratio >= _kThreshold) {
      setState(() => _committing = true);
      final isDelete = _offset > 0;
      // Desliza la card fuera de pantalla y luego ejecuta la acción.
      _runAnim(
        isDelete ? sw + 60 : -(sw + 60),
        ms: _kDismissMs,
        curve: Curves.easeIn,
      ).then((_) {
        if (!mounted) return;
        if (isDelete) {
          // Oculta la card de inmediato para eliminar el fondo rojo residual
          // antes de que las operaciones asíncronas actualicen la BD.
          setState(() => _hidden = true);
          _doDelete();
        } else {
          _doMarkReviewed();
        }
      });
    } else {
      // Spring-back animado al centro.
      _runAnim(0, ms: _kSnapMs, curve: Curves.easeOutBack);
    }
  }

  Future<void> _doMarkReviewed() async {
    final db = ref.read(databaseProvider);
    final s = ref.read(appStringsProvider);
    await db.setLinkReviewed(widget.link.id, true);
    if (!mounted) return;
    // Resetea la posición (para el caso en que la card permanece en lista).
    setState(() {
      _offset = 0;
      _committing = false;
    });
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(s.markedAsReviewed),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: s.undo,
          onPressed: () => db.setLinkReviewed(widget.link.id, false),
        ),
      ));
  }

  Future<void> _doDelete() async {
    // Pre-capturar ScaffoldMessenger ANTES de cualquier await para que siga
    // siendo válido incluso si el stream de Drift desmonta este widget al
    // eliminar el link de la lista reactiva.
    final scaffold = ScaffoldMessenger.of(context);
    final db = ref.read(databaseProvider);
    final s = ref.read(appStringsProvider);

    // Guarda los datos del link y sus relaciones ANTES de borrar para poder deshacer.
    final link = widget.link;
    final tags = await db.getTagsForLink(link.id);
    final collections = await db.getCollectionsForLink(link.id);

    await db.deleteLink(link.id);

    // Usamos la referencia pre-capturada; no depende de `mounted`.
    scaffold
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(s.linkDeleted),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: s.undo,
          onPressed: () => db.restoreLink(link, tags: tags, collections: collections),
        ),
      ));
  }
}
