import 'package:flutter/material.dart';
import 'package:traffic_prediction/responsive_template.dart';

class MapControls extends StatelessWidget {
  final Function directionButton;
  final Function locationButton;
  final Function searchButton;
  final bool showDirectionButton;
  MapControls({
    this.directionButton,
    this.locationButton,
    this.searchButton,
    this.showDirectionButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveTemplate(
      builder: (context, size) {
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.05,
            vertical: size.height * 0.02,
          ),
          child: Column(
            children: [
              Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  showDirectionButton
                      ? Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue.shade600,
                            boxShadow: [
                              BoxShadow(
                                offset: Offset(2, 2),
                                color: Colors.blue.shade100,
                                blurRadius: 3,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: IconButton(
                            color: Colors.white,
                            iconSize: size.height * 0.035,
                            icon: Icon(Icons.directions),
                            onPressed: directionButton,
                          ),
                        )
                      : Container(),
                  Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          offset: Offset(2, 2),
                          color: Colors.blue.shade100,
                          blurRadius: 3,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: IconButton(
                      color: Colors.blue.shade600,
                      iconSize: size.height * 0.032,
                      icon: Icon(Icons.my_location),
                      onPressed: locationButton,
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: size.height * 0.02,
              ),
              GestureDetector(
                onTap: searchButton,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: size.width * 0.035),
                  height: size.height * 0.06,
                  width: size.width,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      size.height * 0.01,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        size: size.height * 0.03,
                        color: Colors.blue.shade600,
                      ),
                      SizedBox(
                        width: size.width * 0.04,
                      ),
                      Text(
                        "Search for routes",
                        style: TextStyle(
                            fontSize: size.height * 0.026,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
