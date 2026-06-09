import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:food_store/screens/cart/cart.screen.dart';
import 'package:food_store/screens/favorite.screen.dart';
import 'package:food_store/screens/store.main.screen.dart';
import 'package:food_store/screens/store_product_page/all_product.screen.dart';
import 'package:flutter/material.dart';
import 'package:food_store/screens/setting/setting.screen.dart';
import '../../shared/components/custom.theme.dart';

Widget? preScreen;

class MainPageScreen extends StatefulWidget {
  final Widget? currentScreen;
  final bool? isBack;
  const MainPageScreen({super.key, this.currentScreen, this.isBack});

  @override
  State<MainPageScreen> createState() => _MainPageScreenState();
}

class _MainPageScreenState extends State<MainPageScreen> {
  int _currentIndex = 0;
  bool isDarkMode = false;

  List<Widget> _getPages() {
    return [
      StoreMainScreen(),
      AllProductScreen(),
      CartPage(),
      FavoriteScreen(),
      SettingScreen(
        isDarkMode: isDarkMode,
        onThemeChanged: (bool value) {
          setState(() {
            isDarkMode = value;
          });
        },
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    final pages = _getPages();

    if (widget.isBack != null && widget.isBack!) {
      _currentIndex =
          pages.indexWhere((wg) => preScreen!.toString() == wg.toString());
    }
    if (widget.currentScreen != null) {
      _currentIndex = pages.indexWhere(
          (wg) => widget.currentScreen!.toString() == wg.toString());
    }
    if (_currentIndex == -1) _currentIndex = 0;
    preScreen = pages[_currentIndex];
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryPink = const Color(0xffFF6584);
    final Color lightBarBg = const Color(0xffFFFFFF);
    final Color darkBarBg = const Color(0xff1E1E1E);

    final Color activeIconColor =
        isDarkMode ? const Color(0xff1E1E1E) : Colors.white;
    final Color inactiveIconColor =
        isDarkMode ? Colors.white38 : const Color(0xffA0A5BD);
    final Color buttonBgColor = primaryPink;

    final backgroundColor = isDarkMode ? darkBarBg : lightBarBg;
    final scaffoldBgColor =
        isDarkMode ? const Color(0xff121212) : const Color(0xffF9F9FB);

    final currentPages = _getPages();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: customLightTheme,
      darkTheme: customDarkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        backgroundColor: scaffoldBgColor,
        body: currentPages[_currentIndex],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDarkMode ? 0.4 : 0.06),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: CurvedNavigationBar(
            index: _currentIndex,
            height: 62.0,
            items: <Widget>[
              _buildAnimatedIcon(Icons.home_rounded, _currentIndex == 0,
                  activeIconColor, inactiveIconColor),
              _buildAnimatedIcon(Icons.restaurant_menu_rounded,
                  _currentIndex == 1, activeIconColor, inactiveIconColor),
              _buildAnimatedIcon(Icons.shopping_cart_rounded,
                  _currentIndex == 2, activeIconColor, inactiveIconColor),
              _buildAnimatedIcon(Icons.favorite_rounded, _currentIndex == 3,
                  activeIconColor, inactiveIconColor),
              _buildAnimatedIcon(Icons.settings_rounded, _currentIndex == 4,
                  activeIconColor, inactiveIconColor),
            ],
            color: backgroundColor,
            buttonBackgroundColor: buttonBgColor,
            backgroundColor: scaffoldBgColor,
            animationCurve: Curves.easeOutBack,
            animationDuration: const Duration(milliseconds: 400),
            onTap: (index) {
              setState(() {
                preScreen = currentPages[_currentIndex];
                _currentIndex = index;
              });
            },
            letIndexChange: (index) => true,
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon(
      IconData icon, bool isSelected, Color activeColor, Color inactiveColor) {
    return AnimatedScale(
      scale: isSelected ? 1.15 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Icon(
        icon,
        size: 26,
        color: isSelected ? activeColor : inactiveColor,
      ),
    );
  }
}
