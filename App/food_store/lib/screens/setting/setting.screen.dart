import 'package:food_store/main.dart';
import 'package:food_store/screens/forgot_password/forgot.password.dart';
import 'package:food_store/screens/user/history.purchase.dart';
import 'package:food_store/screens/user/profile.screen.dart';
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
  String? userEmail;
  String? avatarLink;

  final SharedPreferencesService sharedPreferencesService =
      SharedPreferencesService();
  final SQLiteService sqliteService = SQLiteService();
  late AccountModel curAccount = AccountModel();

  final String defaultAvatar =
      'https://i.pinimg.com/originals/5c/e6/ec/5ce6ec7936ed9aa8c2dd89fe540e36a1.jpg';

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.isDarkMode;
    _loadUserInfo();
    _loadLoginInfo();
  }

  Future<void> _loadLoginInfo() async {
    final prevAccount = await sharedPreferencesService.checkPrevSaveLogin();
    if (prevAccount != null) setState(() => rememberMe = true);
    final link = await sqliteService.getAvatarLink();
    setState(() => avatarLink = link ?? defaultAvatar);
  }

  Future<void> _loadUserInfo() async {
    final account = await sharedPreferencesService.getAccountInfo();
    if (account != null) {
      setState(() {
        userName = account.name;
        userEmail = account.email;
        curAccount = account;
      });
    }
    final link = await sqliteService.getAvatarLink();
    setState(() => avatarLink = link ?? defaultAvatar);
  }

  // Reload sau khi quay về từ ProfileScreen
  Future<void> _goToProfile() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
    _loadUserInfo(); // refresh avatar + tên
  }

  void _showLogoutDialog(Color primaryColor) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDarkMode ? const Color(0xff1E1E1E) : Colors.white,
        title: Text('Đăng xuất?',
            style: TextStyle(
                fontFamily: 'Rubik',
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: isDarkMode ? Colors.white : const Color(0xff1D1D1F))),
        content: Text('Bạn có chắc muốn đăng xuất khỏi tài khoản không?',
            style: TextStyle(
                fontFamily: 'Rubik',
                fontSize: 14,
                color: isDarkMode ? Colors.white54 : Colors.grey.shade600)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy',
                style: TextStyle(
                    fontFamily: 'Rubik',
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white54 : Colors.grey.shade500)),
          ),
          TextButton(
            onPressed: () {
              sharedPreferencesService.saveLoginInfo(
                  curAccount.accountID!, false);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const MyApp()),
                (route) => false,
              );
            },
            child: const Text('Đăng xuất',
                style: TextStyle(
                    fontFamily: 'Rubik',
                    fontWeight: FontWeight.w700,
                    color: Color(0xffFF453A))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor =
        isDarkMode ? const Color(0xffE5386D) : const Color(0xffFF6584);
    final cardColor = isDarkMode ? const Color(0xff1E1E1E) : Colors.white;
    final textColor =
        isDarkMode ? const Color(0xffF5F5F7) : const Color(0xff1D1D1F);
    final subTextColor = isDarkMode ? Colors.white38 : const Color(0xff86868B);
    final scaffoldBgColor =
        isDarkMode ? const Color(0xff121212) : const Color(0xffF5F5F7);
    final dividerColor = Colors.grey.withOpacity(isDarkMode ? 0.15 : 0.12);

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            height: 170,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(36)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
                        colorFilter: const ColorFilter.mode(
                            Colors.white, BlendMode.srcIn),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Text('Cài đặt',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontFamily: 'Rubik',
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        )),
                  ],
                ),
              ),
            ),
          ),

          // ── Body ────────────────────────────────────────────────────────
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -35),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // ── Profile Card ───────────────────────────────────────
                    GestureDetector(
                      onTap: _goToProfile,
                      child: Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withOpacity(isDarkMode ? 0.35 : 0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            // Avatar
                            Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: primaryColor.withOpacity(0.4),
                                        width: 2),
                                  ),
                                  child: CircleAvatar(
                                    radius: 30,
                                    backgroundColor: Colors.grey.shade200,
                                    backgroundImage: NetworkImage(
                                        avatarLink ?? defaultAvatar),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: primaryColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: cardColor, width: 1.5),
                                    ),
                                    child: const Icon(Icons.edit,
                                        color: Colors.white, size: 9),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 14),
                            // Name & email
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userName ?? 'Khách hàng',
                                    style: TextStyle(
                                      fontFamily: 'Rubik',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 17,
                                      color: textColor,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    userEmail ?? 'Chưa có email',
                                    style: TextStyle(
                                      fontFamily: 'Rubik',
                                      fontSize: 13,
                                      color: subTextColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            // Arrow
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.arrow_forward_ios_rounded,
                                  color: primaryColor, size: 14),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── Main Settings Card ─────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withOpacity(isDarkMode ? 0.35 : 0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          _buildListTile(
                            icon: Icons.history_rounded,
                            title: 'Lịch sử mua hàng',
                            textColor: textColor,
                            primaryColor: primaryColor,
                            onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const HistoryPurchaseScreen())),
                          ),
                          _divider(dividerColor),
                          _buildListTile(
                            icon: Icons.lock_reset_rounded,
                            title: 'Quên mật khẩu',
                            textColor: textColor,
                            primaryColor: primaryColor,
                            onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const ForgotPasswordScreen())),
                          ),
                          _divider(dividerColor),
                          _buildListTile(
                            icon: Icons.account_balance_wallet_outlined,
                            title: 'Phương thức thanh toán',
                            textColor: textColor,
                            primaryColor: primaryColor,
                            onTap: () {},
                          ),
                          _divider(dividerColor),
                          // _buildListTile(
                          //   icon: Icons.video_library_outlined,
                          //   title: 'Hướng dẫn sử dụng',
                          //   textColor: textColor,
                          //   primaryColor: primaryColor,
                          //   onTap: () => Navigator.of(context).push(
                          //       MaterialPageRoute(
                          //           builder: (_) => const VideoGuideScreen())),
                          // ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── Preferences Card ───────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withOpacity(isDarkMode ? 0.35 : 0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          _buildSwitchTile(
                            icon: Icons.bookmark_outline_rounded,
                            title: 'Lưu đăng nhập',
                            subtitle: 'Tự động đăng nhập lần sau',
                            value: rememberMe,
                            activeColor: primaryColor,
                            textColor: textColor,
                            subTextColor: subTextColor,
                            isDarkMode: isDarkMode,
                            onChanged: (val) {
                              setState(() {
                                rememberMe = val;
                                sharedPreferencesService.saveLoginInfo(
                                    curAccount.accountID!, val);
                              });
                            },
                          ),
                          _divider(dividerColor),
                          _buildSwitchTile(
                            icon: Icons.dark_mode_outlined,
                            title: 'Chế độ tối',
                            subtitle: 'Giao diện tối cho mắt',
                            value: isDarkMode,
                            activeColor: primaryColor,
                            textColor: textColor,
                            subTextColor: subTextColor,
                            isDarkMode: isDarkMode,
                            onChanged: (val) {
                              setState(() => isDarkMode = val);
                              widget.onThemeChanged(val);
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── Logout Card ────────────────────────────────────────
                    GestureDetector(
                      onTap: () => _showLogoutDialog(primaryColor),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withOpacity(isDarkMode ? 0.35 : 0.04),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: const Color(0xffFF453A).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.logout_rounded,
                                  color: Color(0xffFF453A), size: 20),
                            ),
                            const SizedBox(width: 14),
                            const Text('Đăng xuất',
                                style: TextStyle(
                                  fontFamily: 'Rubik',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: Color(0xffFF453A),
                                )),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // App version
                    Text('CANTEEN YUMMY DELI • v1.0.0',
                        style: TextStyle(
                            fontFamily: 'Rubik',
                            fontSize: 11,
                            color: subTextColor,
                            letterSpacing: 0.5)),
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

  Widget _divider(Color color) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Divider(height: 1, thickness: 0.6, color: color),
      );

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required Color textColor,
    required Color primaryColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: primaryColor, size: 20),
      ),
      title: Text(title,
          style: TextStyle(
              fontFamily: 'Rubik',
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: textColor)),
      trailing: Icon(Icons.chevron_right_rounded,
          color: Colors.grey.shade400, size: 20),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Color activeColor,
    required Color textColor,
    required Color subTextColor,
    required bool isDarkMode,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: activeColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: activeColor, size: 20),
      ),
      title: Text(title,
          style: TextStyle(
              fontFamily: 'Rubik',
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: textColor)),
      subtitle: Text(subtitle,
          style: TextStyle(
              fontFamily: 'Rubik', fontSize: 12, color: subTextColor)),
      trailing: Transform.scale(
        scale: 0.82,
        child: Switch(
          value: value,
          activeColor: Colors.white,
          activeTrackColor: activeColor,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor:
              isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
          trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
