import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluttertoast/fluttertoast.dart';
// import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' as io; // Import dart:io with a prefix
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:url_launcher/url_launcher.dart';

//const platform = MethodChannel('com.savemax.crm/');

const greyColor = Color(0xFFF3F4F8);
const darkGreyColor = Color(0xFFF8F9FA);

const String BaseUrl = 'https://savemax.com';

void showToast({
  required String message,
  ToastGravity gravity = ToastGravity.TOP,
  Color backgroundColor = Colors.red,
  Color textColor = Colors.white,
  double fontSize = 16.0,
}) {
  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_SHORT,
    gravity: gravity,
    timeInSecForIosWeb: 1,
    backgroundColor: backgroundColor,
    textColor: textColor,
    fontSize: fontSize,
  );
}



void showCustomToast(BuildContext context, String message, String imagePath) {
  final overlay = Overlay.of(context);
  final overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: 50.0, // Adjust the position as needed
      left: MediaQuery.of(context).size.width * 0.2,
      right: MediaQuery.of(context).size.width * 0.2,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.only(top: 6.0,bottom: 6.0),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.5),
            border: Border.all(color: Colors.green,width: 1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 3),
              Image.asset(
                imagePath,
                width: 30,
                height: 30,
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color:  Colors.green, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  overlay?.insert(overlayEntry);

  // Remove the toast after a delay
  Future.delayed(const Duration(seconds: 2), () {
    overlayEntry.remove();
  });
}





Future<File> createFile(Uint8List bytes) async {
  final tempDir = await getTemporaryDirectory();
  final file = File('${tempDir.path}/image.png');
  await file.writeAsBytes(bytes);
  return file;
}

Future<dynamic> ShowCapturedWidget(
    BuildContext context, Uint8List capturedImage) {
  return showDialog(
    useSafeArea: false,
    context: context,
    builder: (context) => Scaffold(
      appBar: AppBar(
        title: Text("Captured widget screenshot"),
      ),
      body: Center(
          child: capturedImage != null
              ? Image.memory(capturedImage)
              : Container()),
    ),
  );
}


void launchAppStore(BuildContext context) async {
  final Uri androidUrl = Uri.parse('https://play.google.com/store/apps/details?id=com.savemax.crm');
  final Uri iosUrl = Uri.parse('https://apps.apple.com/us/app/save-max-crm/id6475230392');

  if (Theme.of(context).platform == TargetPlatform.android) {
    if (await canLaunchUrl(androidUrl)) {
      await launchUrl(androidUrl);
    } else {
      throw 'Could not launch $androidUrl';
    }
  } else if (Theme.of(context).platform == TargetPlatform.iOS) {
    if (await canLaunchUrl(iosUrl)) {
      await launchUrl(iosUrl);
    } else {
      throw 'Could not launch $iosUrl';
    }
  }
}


