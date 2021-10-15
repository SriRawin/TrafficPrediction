import 'package:flutter/material.dart';

class ResponsiveTemplate extends StatelessWidget {
  final Widget Function(BuildContext context, SizeInfo info) builder;
  ResponsiveTemplate({this.builder});
  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    SizeInfo size = SizeInfo(height: height, width: width);
    return builder(context, size);
  }
}

class SizeInfo {
  final height;
  final width;
  SizeInfo({this.height, this.width});
}
