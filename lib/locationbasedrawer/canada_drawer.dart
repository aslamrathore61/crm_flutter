// Define the separate ColumnWidget class
import 'package:crm_flutter/model/user_info.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../Component/CircleAvatarWithDefaultImage.dart';
import 'DrawerMenuItem.dart';

class CanadaDrawerWidget extends StatefulWidget {
  final UserInfo? userInfo;
  final dynamic nativeItem;
  final Function onSideMenuItemTap;
  final Function onProfileTap;
  final Function onRadioButtonUpdate;

  CanadaDrawerWidget({
    required this.userInfo,
    required this.nativeItem,
    required this.onSideMenuItemTap,
    required this.onProfileTap,
    required this.onRadioButtonUpdate,
  });

  @override
  State<CanadaDrawerWidget> createState() => _CanadaDrawerWidgetState();
}

class _CanadaDrawerWidgetState extends State<CanadaDrawerWidget> {

  String _selectedOption = "";

  @override
  void initState() {
    super.initState();
    _selectedOption = (widget.userInfo?.available == true) ? "Available" : "On Break";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Sign-in Section

        Container(
          color: Colors.lightBlue.shade900,
          height: 145,
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: GestureDetector(
                  onTap:() {
                   widget.onProfileTap();
                  },
                  child: Row(
                    children: [
                      SizedBox(
                        width: 10,
                      ),
                      CircleAvatarWithDefaultImage(
                        imageUrl: '${widget.userInfo?.profileImageUrl ?? ''}',
                        defaultImageUrl: 'assets/images/profileimage.png',
                        radius: 25.0,
                      ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center, // Center the text vertically
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${widget.userInfo?.name ?? ""}",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),

                              Text(
                                "${widget.userInfo?.department ?? ""}",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade300,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Icon(
                  size: 20,
                  Icons.arrow_forward_ios_sharp,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 4), // Add space between the options

        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedOption = 'Available';
                });
                widget.onRadioButtonUpdate('Available');
              },
              child: Row(
                children: [
                  Radio<String>(
                    fillColor: MaterialStateProperty.resolveWith((states) {
                      return Colors.green.shade700; // Active color
                    }),
                    value: 'Available',
                    groupValue: _selectedOption,
                    onChanged: (value) {
                      setState(() {
                        _selectedOption = value!;
                      });
                      widget.onRadioButtonUpdate(value);
                    },
                  ),
                  Text(
                    'Available',
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            SizedBox(width: 20), // Add space between the options
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedOption = 'On Break';
                });
                widget.onRadioButtonUpdate('On Break');
              },
              child: Row(
                children: [
                  Radio<String>(
                    fillColor: MaterialStateProperty.resolveWith((states) {
                      return Colors.green.shade700; // Active color
                    }),
                    value: 'On Break',
                    groupValue: _selectedOption,
                    onChanged: (value) {
                      setState(() {
                        _selectedOption = value!;
                      });
                      widget.onRadioButtonUpdate(value);
                    },
                  ),
                  Text(
                    'On Break',
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),

        SizedBox(height: 4), // Add space between the options

        Container(
          width: double.infinity, // Thickness of the divider
          height: 1.0, // Matches the parent's height
          color: Colors.grey.shade300, // Color of the divider
        ),

        // Side Menu
        Container(
          color: Colors.white,
          child: ListView.builder(
              shrinkWrap: true,
              primary: false,
              // Prevents issues with parent scroll views
              padding: const EdgeInsets.all(8),
              itemCount: widget.nativeItem.side?.length,
              itemBuilder: (BuildContext context, int index) {
                return DrawerMenuItem(
                    key: ValueKey(widget.nativeItem.side![index].id),
                    urlValue: widget.nativeItem.side![index].uRL!,
                    sideMenu: widget.nativeItem.side![index],
                    onTap: (String url, String id, String icon) async {
                      //if user get selected currency then reload url as symbol currency
                      widget.onSideMenuItemTap(url, id, icon);
                    });
              }),
        ),

     //   Spacer(), // Pushes the next widget to the bottom






      ],
    );
  }
}
