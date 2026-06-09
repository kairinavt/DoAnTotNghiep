import 'package:food_store/data/api_repository.dart';
import 'package:food_store/models/authorize/signup.model.dart';
import 'package:food_store/screens/forgot_password/forgot.password.dart';
import 'package:food_store/screens/mainpage/mainpage.screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:food_store/services/share_pre.dart';
import 'package:food_store/services/sqlite_pro5.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

const Color kPink = Color(0xFFf56789);
const Color kPinkLight = Color(0xFFFFECF0);
const Color kPinkDark = Color(0xFFD94F6E);
const Color kBg = Color(0xFFFDF6F8);
const Color kTextDark = Color(0xFF1A1A2E);
const Color kTextGrey = Color(0xFF9E9E9E);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _avatarController = TextEditingController();

  String? _id;
  String? _avatarLink;
  File? _localImage; // ảnh chọn từ thư viện
  bool _isLoading = false;
  bool _isSaving = false;

  static final APIRepository _apiRepository = APIRepository();
  final SharedPreferencesService _prefs = SharedPreferencesService();
  final SQLiteService _sqliteService = SQLiteService();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _avatarController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    setState(() => _isLoading = true);
    final account = await _prefs.getAccountInfo();
    if (account != null) {
      _id = account.accountID;
      _nameController.text = account.name;
      _emailController.text = account.email;
      _phoneController.text = account.phone;
    }
    final link = await _sqliteService.getAvatarLink();
    setState(() {
      _avatarLink = link;
      if (link != null) _avatarController.text = link;
      _isLoading = false;
    });
  }

  Future<void> _pickFromGallery() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() {
        _localImage = File(picked.path);
        _avatarController.clear(); // ưu tiên ảnh local
      });
      Navigator.pop(context);
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      _toast('Vui lòng nhập tên', isError: true);
      return;
    }
    setState(() => _isSaving = true);

    // Save avatar
    if (_avatarController.text.isNotEmpty) {
      if (_avatarLink == null) {
        await _sqliteService.saveAvatarLink(_avatarController.text);
      } else {
        await _sqliteService.updateAvatarLink(_avatarController.text);
      }
      _avatarLink = _avatarController.text;
    }

    // Update profile
    final account = AccountModel()
      ..accountID = _id ?? ''
      ..name = _nameController.text.trim()
      ..email = _emailController.text.trim()
      ..phone = _phoneController.text.trim()
      ..password = ''; // password not changed here

    final success = await _apiRepository.updateProfile(account);
    setState(() => _isSaving = false);

    if (success) {
      await _prefs.saveAccountInfo(account);
      _toast('Cập nhật thành công!');
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const MainPageScreen()));
    } else {
      _toast('Cập nhật thất bại, thử lại!', isError: true);
    }
  }

  void _toast(String msg, {bool isError = false}) {
    Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: isError ? Colors.red.shade400 : Colors.green.shade400,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  // ảnh local ưu tiên hơn link URL
  bool get _hasLocalImage => _localImage != null;

  String get _previewAvatar => _avatarController.text.isNotEmpty
      ? _avatarController.text
      : (_avatarLink ??
          'https://i.pinimg.com/originals/5c/e6/ec/5ce6ec7936ed9aa8c2dd89fe540e36a1.jpg');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kPink))
          : CustomScrollView(
              slivers: [
                _buildAppBar(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        _buildAvatarSection(),
                        const SizedBox(height: 32),
                        _buildFormCard(),
                        const SizedBox(height: 16),
                        _buildChangePasswordTile(),
                        const SizedBox(height: 32),
                        _buildSaveButton(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ── App Bar ──────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      pinned: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            size: 18, color: kTextDark),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text('Thông tin tài khoản',
          style: TextStyle(
              color: kTextDark, fontSize: 17, fontWeight: FontWeight.w800)),
      centerTitle: true,
      actions: [
        TextButton(
          onPressed: _isSaving ? null : _saveProfile,
          child: const Text('Lưu',
              style: TextStyle(
                  color: kPink, fontSize: 14, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  // ── Avatar ───────────────────────────────────────────────────────────────
  Widget _buildAvatarSection() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: kPink, width: 3),
                boxShadow: [
                  BoxShadow(
                      color: kPink.withOpacity(0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 6))
                ],
              ),
              child: ClipOval(
                child: _hasLocalImage
                    ? Image.file(_localImage!, fit: BoxFit.cover)
                    : Image.network(
                        _previewAvatar,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                            color: kPinkLight,
                            child: const Icon(Icons.person,
                                color: kPink, size: 44)),
                      ),
              ),
            ),
            GestureDetector(
              onTap: _showAvatarSheet,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [kPink, kPinkDark]),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
            _nameController.text.isNotEmpty
                ? _nameController.text
                : 'Tên của bạn',
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800, color: kTextDark)),
        const SizedBox(height: 4),
        Text(_emailController.text,
            style: const TextStyle(fontSize: 13, color: kTextGrey)),
      ],
    );
  }

  void _showAvatarSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Align(
              alignment: Alignment.centerLeft,
              child: Text('Đổi ảnh đại diện',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: kTextDark))),
          const SizedBox(height: 16),

          // Chọn từ thư viện
          _sheetOption(
            icon: Icons.photo_library_outlined,
            label: 'Chọn từ thư viện',
            sub: 'Ảnh từ điện thoại của bạn',
            onTap: _pickFromGallery,
          ),
          const SizedBox(height: 10),

          // // Dán link URL
          // _sheetOption(
          //   icon: Icons.link_rounded,
          //   label: 'Dán link URL',
          //   sub: 'Nhập địa chỉ hình ảnh online',
          //   onTap: () {
          //     Navigator.pop(context);
          //     _showLinkSheet();
          //   },
          // ),
        ]),
      ),
    );
  }

  Widget _sheetOption({
    required IconData icon,
    required String label,
    required String sub,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
            color: kBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200)),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: kPinkLight, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: kPink, size: 20),
          ),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: kTextDark)),
            Text(sub, style: const TextStyle(fontSize: 12, color: kTextGrey)),
          ]),
          const Spacer(),
          const Icon(Icons.arrow_forward_ios_rounded,
              size: 13, color: kTextGrey),
        ]),
      ),
    );
  }

  void _showLinkSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 30),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Align(
              alignment: Alignment.centerLeft,
              child: Text('Dán link ảnh',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: kTextDark))),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
                color: kBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200)),
            child: TextField(
              controller: _avatarController,
              autofocus: true,
              style: const TextStyle(fontSize: 14, color: kTextDark),
              decoration: const InputDecoration(
                hintText: 'https://...',
                hintStyle: TextStyle(color: kTextGrey),
                prefixIcon: Icon(Icons.link_rounded, color: kPink, size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _localImage = null;
                }); // bỏ ảnh local nếu dán link
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: kPink,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0),
              child: const Text('Xác nhận',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Form Card ────────────────────────────────────────────────────────────
  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 16,
                offset: const Offset(0, 4))
          ]),
      child: Column(children: [
        _buildField(
          icon: Icons.person_outline_rounded,
          label: 'Họ và tên',
          controller: _nameController,
          isFirst: true,
        ),
        _divider(),
        _buildField(
          icon: Icons.email_outlined,
          label: 'Email',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
        ),
        _divider(),
        _buildField(
          icon: Icons.phone_outlined,
          label: 'Số điện thoại',
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          isLast: true,
        ),
      ]),
    );
  }

  Widget _buildField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool isFirst = false,
    bool isLast = false,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Padding(
      padding: EdgeInsets.only(top: isFirst ? 4 : 0, bottom: isLast ? 4 : 0),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        style: const TextStyle(fontSize: 14, color: kTextDark),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: kTextGrey, fontSize: 13),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 8),
            child: Icon(icon, color: kPink, size: 20),
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 0, minHeight: 0),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
      ),
    );
  }

  Widget _divider() => Divider(
      height: 1, indent: 56, endIndent: 16, color: Colors.grey.shade100);

  // ── Change Password Tile ─────────────────────────────────────────────────
  Widget _buildChangePasswordTile() {
    return GestureDetector(
      onTap: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 3))
            ]),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: kPinkLight, borderRadius: BorderRadius.circular(10)),
            child:
                const Icon(Icons.lock_outline_rounded, color: kPink, size: 18),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Đổi mật khẩu',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: kTextDark)),
              Text('Cập nhật mật khẩu của bạn',
                  style: TextStyle(fontSize: 12, color: kTextGrey)),
            ]),
          ),
          const Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: kTextGrey),
        ]),
      ),
    );
  }

  // ── Save Button ──────────────────────────────────────────────────────────
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: kPink,
          disabledBackgroundColor: kPink.withOpacity(0.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          shadowColor: kPink.withOpacity(0.4),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
            : const Text('Lưu thay đổi',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
      ),
    );
  }
}
