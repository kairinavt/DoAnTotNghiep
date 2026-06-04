import 'package:food_store/assets/custom_icon.dart';
import 'package:food_store/constants/colors.dart';
import 'package:food_store/screens/user/profile.screen.dart';
import 'package:flutter/material.dart';

Padding mainPageHeader(GlobalKey<ScaffoldState> scaffoldKey, BuildContext context) {
  return Padding(
    padding: EdgeInsets.only(top: MediaQuery.of(context).size.height*5/100),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            RotatedBox(
              quarterTurns: 1,
              child: IconButton(
                onPressed: () { scaffoldKey.currentState?.openDrawer(); }, 
                icon: const Icon(
                  Icons.bar_chart_rounded,
                  color: iconColor,
                  size: 30,
                )
              ),
            ),
            const Text(
              "CANTEEN YUMMY DELI",
              style: TextStyle(color: iconColor, fontSize: 18),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              onPressed: () {}, 
              icon: const Icon(
                CustomIcon.custom_notification,
                color: iconColor,
                size: 24,
              )
            ),
            IconButton(
              onPressed: () { Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ProfileScreen())); }, 
              icon: const Icon(
                CustomIcon.custom_user,
                color: iconColor,
                size: 24,
              )
            ),
          ],
        ),
      ],
    ),
  );
}