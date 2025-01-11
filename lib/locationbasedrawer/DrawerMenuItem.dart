// Main Drawer Menu Item
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../model/native_item.dart';

class DrawerMenuItem extends StatefulWidget {

  final Side sideMenu;
  final String urlValue;
  final Function onTap;
  const DrawerMenuItem({Key? key, required this.urlValue,required this.sideMenu,
    required this.onTap,}) : super(key: key);

  @override
  State<DrawerMenuItem> createState() => _DrawerMenuItemState();
}

class _DrawerMenuItemState extends State<DrawerMenuItem> {
  late ImageProvider _iconMenuProvider;
  late String svgString;

  @override
  void initState() {
    super.initState();

    _iconMenuProvider = MemoryImage(base64Decode(widget.sideMenu.menuIcon!));
    if(widget.sideMenu.icon != null && widget.sideMenu.icon!.isNotEmpty) {
      final svgBytes = base64Decode(widget.sideMenu.icon!);
      svgString = utf8.decode(svgBytes);
    }else{
      svgString = "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        widget.onTap(widget.sideMenu.uRL, widget.sideMenu.id, "");
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            height: 45,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  width: 8,
                ),

                if(svgString.isNotEmpty)
                SvgPicture.string(
                  svgString,
                  color: Colors.grey.shade600,
                  width: 18.0,
                  height: 18.0,
                ),

                SizedBox(width: 13),
                widget.sideMenu.menuIcon!.isNotEmpty
                    ? Image(
                    color: Colors.grey.shade600,
                    image: _iconMenuProvider,
                    width: 30,
                    height: 30,
                    fit: BoxFit.contain)
                    : SizedBox(width: 0),
                SizedBox(width: 4),

                Text(
                  widget.sideMenu.title!,
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.black,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

