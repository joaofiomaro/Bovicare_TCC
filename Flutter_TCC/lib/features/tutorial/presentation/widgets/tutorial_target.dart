import 'package:flutter/widgets.dart';

/// Marca um elemento da tela para o tutorial destacar. Não muda nada no
/// layout: só registra onde o [child] está, pelo [id] usado nos passos.
class TutorialTarget extends StatefulWidget {
  const TutorialTarget({required this.id, required this.child, super.key});

  final String id;
  final Widget child;

  /// Contexto do elemento marcado com [id], se estiver montado.
  static BuildContext? contextOf(String id) {
    final state = _registry[id];
    return state != null && state.mounted ? state.context : null;
  }

  static final _registry = <String, _TutorialTargetState>{};

  @override
  State<TutorialTarget> createState() => _TutorialTargetState();
}

class _TutorialTargetState extends State<TutorialTarget> {
  @override
  void initState() {
    super.initState();
    TutorialTarget._registry[widget.id] = this;
  }

  @override
  void didUpdateWidget(TutorialTarget old) {
    super.didUpdateWidget(old);
    if (old.id != widget.id) {
      _unregister(old.id);
      TutorialTarget._registry[widget.id] = this;
    }
  }

  void _unregister(String id) {
    // Outra instância pode ter assumido o mesmo id (tela empilhada).
    if (identical(TutorialTarget._registry[id], this)) {
      TutorialTarget._registry.remove(id);
    }
  }

  @override
  void dispose() {
    _unregister(widget.id);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
