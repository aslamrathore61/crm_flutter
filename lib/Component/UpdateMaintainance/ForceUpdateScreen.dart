import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:lottie/lottie.dart';

import '../../Utils/constants.dart';
import '../buttons/socal_button.dart';

class ForceUpdateScreen extends StatelessWidget {
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
                child: Column(
                  children: [


                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Rise CRM',style: TextStyle(color: Color(0xFF0054a0), fontSize: 18, fontWeight: FontWeight.bold),),
                       // Text(' CRM',style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold),),
                      ],
                    ),

                  ],
                ),
            ),
          Container(
               child: Lottie.asset(
                      'assets/lottie/force_update.json', // Update this to your actual Lottie file path
                      repeat: true,
                      animate: true,
                    ),
             ),


            Column(
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 14.0), // Equivalent to @dimen/_14sdp
                    child: Text(
                      'Update Available!', // Update this to your actual string resource
                      style: TextStyle(
                        fontSize: 20.0, // Equivalent to @dimen/_20sdp
                        color: Color(0xFF000000), // Equivalent to @color/dark
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0), // Equivalent to @dimen/_8sdp
                    padding: EdgeInsets.all(8.0), // Equivalent to @dimen/_8sdp
                    child: Text(
                      'A new version of the application is available. For the best app experience, please update to the latest version.', // Update this to your actual string resource
                      style: TextStyle(
                        fontSize: 16.0, // Equivalent to @dimen/_16sdp
                        color: Color(0xFF000000), // Equivalent to @color/dark
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                ],
            ),

            Container(
                margin: EdgeInsets.all(16.0), // Equivalent to @dimen/_16sdp
                child: SocalButton(
                  color: Color(0xFF0054a0),
                  icon: Icon(Icons.download,
                      color: Colors.white, size: 16),
                  press: () {
                    launchAppStore(context);
                  },
                  text: "Update Now",
                ),
              ),
          ],
        ),
      ),
    );
  }
}
