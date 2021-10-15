import 'package:flutter/material.dart';

class SlideUp extends PageRouteBuilder {
  final Widget nextPage;
  SlideUp({this.nextPage})
      : super(
            pageBuilder: (context, animation, secondaryAnimation) => nextPage,
            transitionDuration: Duration(milliseconds: 200),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              var start = Offset(0, 1);
              var end = Offset.zero;
              var curve = Curves.ease;
              var tween =
                  Tween(begin: start, end: end).chain(CurveTween(curve: curve));

              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            });
}
