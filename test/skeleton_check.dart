import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

void main() {
  const effect = ShimmerEffect(
    baseColor: Color(0xFFE9EEF5),
    highlightColor: Colors.white,
  );
  print(effect);
}
