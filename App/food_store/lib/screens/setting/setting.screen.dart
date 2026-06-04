import 'package:food_store/main.dart';
import 'package:food_store/screens/forgot_password/forgot.password.dart';
import 'package:food_store/screens/setting/video_guide_screen.dart';
import 'package:food_store/screens/user/history.purchase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:food_store/services/share_pre.dart';
import 'package:food_store/services/sqlite_pro5.dart';
import 'package:food_store/models/authorize/signup.model.dart';

class SettingScreen extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  const SettingScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  _SettingScreenState createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  bool rememberMe = false;
  late bool isDarkMode;

  String? userName;
  String? avatarLink;

  final SharedPreferencesService sharedPreferencesService = SharedPreferencesService();
  final SQLiteService sqliteService = SQLiteService();
  late AccountModel curAccount = AccountModel();

  final String defaultAvatar = 'https://i.pinimg.com/originals/5c/e6/ec/5ce6ec7936ed9aa8c2dd89fe540e36a1.jpg';

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.isDarkMode;
    _loadUserInfo();
    _loadLoginInfo();
  }

  Future<void> _loadLoginInfo() async {
    String? prevAccount = await sharedPreferencesService.checkPrevSaveLogin();
    if (prevAccount != null) {
      setState(() {
        rememberMe = true;
      });
    }

    String? link = await sqliteService.getAvatarLink();
    setState(() {
      avatarLink = link ?? defaultAvatar;
    });
  }

  Future<void> _loadUserInfo() async {
    AccountModel? account = await sharedPreferencesService.getAccountInfo();
    if (account != null) {
      setState(() {
        userName = account.name;
        curAccount = account;
      });
    }

    String? link = await sqliteService.getAvatarLink();
    setState(() {
      avatarLink = link ?? defaultAvatar;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Bảng màu Premium Pastel & Deep Dark
    final primaryColor = isDarkMode ? const Color(0xffE5386D) : const Color(0xffFF6584);
    final cardColor = isDarkMode ? const Color(0xff1E1E1E) : Colors.white;
    final textColor = isDarkMode ? const Color(0xffF5F5F7) : const Color(0xff1D1D1F);
    final subTextColor = isDarkMode ? Colors.white38 : const Color(0xff86868B);
    final scaffoldBgColor = isDarkMode ? const Color(0xff121212) : const Color(0xffF5F5F7);

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      body: Column(
        children: [
          Container(
            height: 170,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withOpacity(0.85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(36),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: SvgPicture.asset(
                        'assets/vectors/setting.svg',
                        height: 24,
                        width: 24,
                        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      'Cài đặt',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontFamily: 'Rubik',
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Nội dung chính lướt cuộn mượt mà
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -35),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Khối Profile & Menu được bọc chung trong một Card bo góc mịn
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDarkMode ? 0.4 : 0.04),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                      child: Column(
                        children: [
                          // User Profile Row tinh tế
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: primaryColor.withOpacity(0.15), width: 2),
                                  ),
                                  child: CircleAvatar(
                                    radius: 30,
                                    backgroundColor: Colors.grey.shade200,
                                    backgroundImage: NetworkImage(avatarLink ?? defaultAvatar),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        userName ?? 'Khách hàng',
                                        style: TextStyle(
                                          fontFamily: 'Rubik',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 18,
                                          color: textColor,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Tài khoản thành viên VIP',
                                        style: TextStyle(
                                          fontFamily: 'Rubik',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: subTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Divider(thickness: 0.6, color: Colors.grey.withOpacity(0.15)),
                          ),

                          // Danh sách tính năng chính
                          _buildListTile(
                            icon: Icons.history_rounded,
                            title: 'Lịch sử mua hàng',
                            textColor: textColor,
                            primaryColor: primaryColor,
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => const HistoryPurchaseScreen()));
                            },
                          ),
                          _buildListTile(
                            icon: Icons.lock_reset_rounded,
                            title: 'Quên mật khẩu',
                            textColor: textColor,
                            primaryColor: primaryColor,
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => const ForgotPasswordScreen()));
                            },
                          ),
                          _buildListTile(
                            icon: Icons.account_balance_wallet_outlined,
                            title: 'Phương thức thanh toán',
                            textColor: textColor,
                            primaryColor: primaryColor,
                            onTap: () {},
                          ),
                          
                          _buildSwitchTile(
                            icon: Icons.bookmark_outline_rounded,
                            title: 'Lưu đăng nhập',
                            value: rememberMe,
                            activeColor: primaryColor,
                            textColor: textColor,
                            isDarkMode: isDarkMode,
                            onChanged: (bool value) {
                              setState(() {
                                sharedPreferencesService.saveLoginInfo(curAccount.accountID!, value);
                                rememberMe = value;
                              });
                            },
                          ),
                          _buildSwitchTile(
                            icon: Icons.dark_mode_outlined,
                            title: 'Chế độ tối',
                            value: isDarkMode,
                            activeColor: primaryColor,
                            textColor: textColor,
                            isDarkMode: isDarkMode,
                            onChanged: (bool value) {
                              setState(() {
                                isDarkMode = value;
                              });
                              widget.onThemeChanged(value);
                            },
                          ),
                          _buildListTile(
                            icon: Icons.video_library_outlined,
                            title: 'Hướng dẫn sử dụng',
                            textColor: textColor,
                            primaryColor: primaryColor,
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => const VideoGuideScreen()));
                            },
                          ),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Divider(thickness: 0.6, color: Colors.grey.withOpacity(0.15)),
                          ),

                          // Nút đăng xuất phá cách màu đỏ mềm mại
                          _buildListTile(
                            icon: Icons.logout_rounded,
                            title: 'Đăng xuất',
                            textColor: const Color(0xffFF453A),
                            primaryColor: const Color(0xffFF453A),
                            showChevron: false,
                            onTap: () {
                              sharedPreferencesService.saveLoginInfo(curAccount.accountID!, false);
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => const MyApp()),
                                (Route<dynamic> route) => false,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required Color textColor,
    required Color primaryColor,
    required Function() onTap,
    bool showChevron = true,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 1),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: primaryColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Rubik',
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: textColor,
        ),
      ),
      trailing: showChevron ? Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20) : null,
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required Color activeColor,
    required Color textColor,
    required bool isDarkMode,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 1),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: activeColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: activeColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Rubik',
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: textColor,
        ),
      ),
      trailing: Transform.scale(
        scale: 0.8,
        child: Switch(
          value: value,
          activeColor: Colors.white,
          activeTrackColor: activeColor,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
          trackOutlineColor: WidgetStateProperty.all(Colors.transparent), 
          onChanged: onChanged,
        ),
      ),
    );
  }
}