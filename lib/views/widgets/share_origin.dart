import 'package:flutter/material.dart';

Rect? shareOriginOf(BuildContext context) {
  if (!context.mounted) return null;

  final RenderObject? object = context.findRenderObject();
  if (object is! RenderBox || !object.hasSize) return null;

  return object.localToGlobal(Offset.zero) & object.size;
}
