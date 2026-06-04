import 'package:flutter/material.dart';

class AddressSearchScreen extends StatefulWidget {
  final String currentAddress;
  const AddressSearchScreen({super.key, required this.currentAddress});

  @override
  State<AddressSearchScreen> createState() => _AddressSearchScreenState();
}

class _AddressSearchScreenState extends State<AddressSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  String _addressType = 'Nhà riêng'; // 'Nhà riêng', 'Công ty', 'Khác'

  // Giả lập danh sách gợi ý địa chỉ giống Google Maps API trả về khi gõ
  List<String> _recentAddresses = [
    'Chung cư Sunrise City, Đường Nguyễn Hữu Thọ, Quận 7, TP. HCM',
    'Đại học Tôn Đức Thắng, 19 Nguyễn Hữu Thọ, Tân Phong, Quận 7',
    'Bitexco Financial Tower, 2 Hải Triều, Bến Nghé, Quận 1, TP. HCM',
    'Landmark 81, Điện Biên Phủ, Phường 22, Bình Thạnh, TP. HCM',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.currentAddress;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Chọn địa chỉ giao hàng',
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // 1. Thanh tìm kiếm địa chỉ chính
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Tìm tòa nhà, tên đường, số nhà...',
                  prefixIcon: const Icon(Icons.location_on, color: Colors.redAccent),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () => setState(() => _searchController.clear()),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged: (val) => setState(() {}),
              ),
            ),
          ),

          // 2. Tùy chọn Loại địa chỉ (Tag Gắn nhãn giống Grab)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                _buildTypeChip('Nhà riêng', Icons.home),
                const SizedBox(width: 8),
                _buildTypeChip('Công ty', Icons.business),
                const SizedBox(width: 8),
                _buildTypeChip('Khác', Icons.push_pin),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 3. Ô nhập ghi chú chi tiết (Số tầng/Số phòng...)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: 'Ghi chú cho tài xế (Ví dụ: Lầu 4, Phòng 402...)',
                hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                prefixIcon: const Icon(Icons.edit_note, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xfff56789)),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(thickness: 6, color: Color(0xFFF5F5F5)),

          // 4. Danh sách địa chỉ gợi ý/Lịch sử
          Expanded(
            child: ListView.builder(
              itemCount: _recentAddresses.length,
              itemBuilder: (context, index) {
                final addr = _recentAddresses[index];
                return ListTile(
                  onTap: () {
                    setState(() => _searchController.text = addr);
                  },
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFF2F2F2),
                    child: Icon(Icons.history, color: Colors.grey, size: 20),
                  ),
                  title: Text(
                    addr,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                );
              },
            ),
          ),

          // 5. Nút Xác nhận dưới cùng màn hình
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _searchController.text.trim().isEmpty
                      ? null
                      : () {
                          // Gom thông tin lại gửi trả về màn hình checkout
                          String fullResult = '[$_addressType] ${_searchController.text}';
                          if (_noteController.text.isNotEmpty) {
                            fullResult += ' (${_noteController.text})';
                          }
                          Navigator.pop(context, fullResult);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xfff56789),
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Xác nhận địa chỉ này',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String label, IconData icon) {
    final isSelected = _addressType == label;
    return ChoiceChip(
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey),
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xfff56789),
      backgroundColor: Colors.grey.shade100,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? const Color(0xfff56789) : Colors.transparent),
      ),
      onSelected: (selected) {
        if (selected) setState(() => _addressType = label);
      },
    );
  }
}