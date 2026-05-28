import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'teacher_home.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import '../shared/settings_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import '../../widgets/teacher_speed_dial.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  String _selectedFilter = "الكل";
  bool _isLoading = false;
  String _searchQuery = '';

  // المحادثات: مجموعة حسب الطرف الآخر
  List<Map<String, dynamic>> _conversations = [];

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final res = await Dio().get(
        "${ApiService().baseUrl}/teacher/messages",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (res.statusCode == 200 && res.data['success'] == true) {
        final messages = (res.data['data'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        // تجميع الرسائل حسب الطرف الآخر (آخر رسالة لكل محادثة)
        final Map<String, Map<String, dynamic>> convMap = {};
        for (final msg in messages) {
          final party = msg['other_party'] as String? ?? 'غير معروف';
          if (!convMap.containsKey(party)) {
            convMap[party] = {
              'name':      party,
              'message':   msg['message'] as String? ?? '',
              'time':      msg['sent_at'] as String? ?? '',
              'is_read':   msg['is_read'] == true,
              'direction': msg['direction'] as String? ?? 'sent',
            };
          }
        }

        setState(() {
          _conversations = convMap.values.toList();
        });
      }
    } catch (e) {
      debugPrint('⛔ Messages Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    var list = _conversations;
    if (_selectedFilter == 'غير مقروءة') {
      list = list.where((c) => c['is_read'] != true).toList();
    }
    if (_searchQuery.isNotEmpty) {
      list = list
          .where((c) => (c['name'] as String)
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final bgColor   = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_forward, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "الرسائل",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: textColor),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          children: [
            Column(
              children: [
                // شريط البحث
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    textAlign: TextAlign.right,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: "ابحث في المحادثات...",
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                // أزرار الفلترة
                _buildFilterRow(cardColor, textColor),
                const SizedBox(height: 10),

                // القائمة
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFFFFCC00)),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchMessages,
                          color: const Color(0xFFFFCC00),
                          child: _filtered.isEmpty
                              ? ListView(
                                  children: const [
                                    SizedBox(height: 80),
                                    Center(
                                      child: Text(
                                        'لا توجد رسائل',
                                        style: TextStyle(
                                            color: Colors.grey, fontSize: 15),
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.fromLTRB(
                                      20, 8, 20, 120),
                                  itemCount: _filtered.length,
                                  itemBuilder: (context, index) =>
                                      _buildChatTile(
                                          context, _filtered[index]),
                                ),
                        ),
                ),
              ],
            ),

            // الشريط السفلي
            CustomBottomNav(
              currentIndex: 3,
              centerButton: const CustomSpeedDialEduBridge(),
              onHomeTap: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const TeacherHomeScreen())),
              onProfileTap: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen())),
              onNotificationsTap: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(
                      builder: (_) => const NotificationsScreen())),
              onMessagesTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow(Color cardColor, Color textColor) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: ["الكل", "غير مقروءة"].map((label) {
          final isSelected = _selectedFilter == label;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = label),
            child: Container(
              margin: const EdgeInsets.only(left: 10),
              padding:
                  const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFFCC00) : cardColor,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.black : textColor,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChatTile(BuildContext context, Map<String, dynamic> chat) {
    final cardColor = Theme.of(context).cardColor;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final isUnread  = chat['is_read'] != true;
    final name      = chat['name'] as String? ?? '';
    final initial   = name.isNotEmpty ? name[0] : '؟';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        border: isUnread
            ? Border.all(
                color: const Color(0xFFFFCC00).withValues(alpha: 0.4),
                width: 1)
            : null,
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: const Color(0xFFEBF5FB),
          child: Text(
            initial,
            style: const TextStyle(
                color: Color(0xFF2E86C1), fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          name,
          style: TextStyle(
              fontWeight: FontWeight.bold, color: textColor),
        ),
        subtitle: Text(
          chat['message'] as String? ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.grey),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              chat['time'] as String? ?? '',
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
            if (isUnread)
              Container(
                margin: const EdgeInsets.only(top: 5),
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFCC00),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
