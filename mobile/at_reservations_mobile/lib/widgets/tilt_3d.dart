import 'package:flutter/material.dart';

// ─── Effet tilt 3D au toucher ──────────────────────────────────
// Wraps any widget with a 3D perspective tilt driven by finger position.
class Tilt3D extends StatefulWidget {
  final Widget child;
  final double intensity;
  const Tilt3D({super.key, required this.child, this.intensity = 0.25});

  @override
  State<Tilt3D> createState() => _Tilt3DState();
}

class _Tilt3DState extends State<Tilt3D> with SingleTickerProviderStateMixin {
  double _rx = 0, _ry = 0;
  double _savedRx = 0, _savedRy = 0;
  late final AnimationController _returnCtrl;
  late final Animation<double> _returnAnim;

  @override
  void initState() {
    super.initState();
    _returnCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    _returnAnim = CurvedAnimation(parent: _returnCtrl, curve: Curves.easeOut);
    _returnCtrl.addListener(() {
      final t = 1 - _returnAnim.value;
      setState(() {
        _rx = _savedRx * t;
        _ry = _savedRy * t;
      });
    });
  }

  @override
  void dispose() {
    _returnCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onPanUpdate: (d) {
      _returnCtrl.stop();
      final rb = context.findRenderObject() as RenderBox?;
      if (rb == null) return;
      final sz = rb.size;
      setState(() {
        _rx = -(d.localPosition.dy / sz.height - 0.5) * widget.intensity;
        _ry =  (d.localPosition.dx / sz.width  - 0.5) * widget.intensity;
      });
    },
    onPanEnd: (_) {
      _savedRx = _rx;
      _savedRy = _ry;
      _returnCtrl.forward(from: 0);
    },
    onPanCancel: () {
      _savedRx = _rx;
      _savedRy = _ry;
      _returnCtrl.forward(from: 0);
    },
    child: Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateX(_rx)
        ..rotateY(_ry),
      child: widget.child,
    ),
  );
}
