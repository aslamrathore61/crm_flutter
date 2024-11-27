import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import 'package:lottie/lottie.dart';
import '../../Utils/constants.dart';

import '../buttons/socal_button.dart';

class MaintenanceScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
        padding: EdgeInsets.all(16.0), // Equivalent to @dimen/activity_vertical_margin
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Container(
                margin: EdgeInsets.symmetric(horizontal: 28.0, vertical: 28.0),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Sync CRM',style: TextStyle(color: Color(0xFF0054a0), fontSize: 18, fontWeight: FontWeight.bold),),
                        SizedBox(height: 6,),
                        Text(' Under Maintenance!',style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w400),),
                      ],
                    ),


                  ],
                ),
            ),

         Container(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset(
                      'assets/lottie/gears.json', // Update this to your actual Lottie file path
                      repeat: true,
                      animate: true,
                    ),
                  ],
                ),
            ),

            Container(
                margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0), // Equivalent to @dimen/_8sdp
                padding: EdgeInsets.all(8.0), // Equivalent to @dimen/_8sdp
                child: Column(
                  children: [
                    Text(
                      'We are currently performing maintenance to improve our services. The application will be temporarily unavailable, Please try after sometime.', // Update this to your actual string resource
                      style: TextStyle(
                        fontSize: 16.0, // Equivalent to @dimen/_16sdp
                        color: Color(0xFF000000), // Equivalent to @color/dark
                      ),
                      textAlign: TextAlign.center,
                    ),

                  ],
                ),
            ),

            Container(
              margin: EdgeInsets.only(left: 16.0, right: 16.0), // Equivalent to @dimen/_16sdp
              child: SocalButton(
                color: Color(0xFF0054a0),
                icon: null,
                press: () {
                  SystemNavigator.pop();
                },
                text: "Exit",
              ),
            ),
          ],
        ),
      ),
    );
  }
}
