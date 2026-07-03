import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:ui' as ui;

import 'package:edu_pridge_flutter/widgets/Affairs_Officer_speed_dial.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';

import 'package:edu_pridge_flutter/screens/Affairs_Officer/nav_bar/home_screen.dart';
import 'package:edu_pridge_flutter/screens/Affairs_Officer/nav_bar/profile_screen.dart';
import 'package:edu_pridge_flutter/screens/Affairs_Officer/nav_bar/notifications_screen.dart';
import 'package:edu_pridge_flutter/screens/Affairs_Officer/nav_bar/messages_screen.dart';
import 'package:edu_pridge_flutter/services/affairs_services.dart';

class AffairsOfficerCalendarScreen extends StatefulWidget {
  const AffairsOfficerCalendarScreen({super.key});

  @override
  State<AffairsOfficerCalendarScreen> createState() => _AffairsOfficerCalendarScreenState();
}

class _AffairsOfficerCalendarScreenState extends State<AffairsOfficerCalendarScreen> {
  final AffairsServices _affairsServices = AffairsServices();

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  bool _isLoading = true;
  List<dynamic> _rawEvents = [];
  final Map<DateTime, List<Map<String, dynamic>>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final data = await _affairsServices.getCalendarEvents();
      if (mounted) {
        setState(() {
          _rawEvents = data ?? [];
          _events.clear();

          for (var item in _rawEvents) {
            final dateStr = item['event_date'] as String?;
            if (dateStr != null) {
              final date = DateTime.tryParse(dateStr);
              if (date != null) {
                final key = DateTime(date.year, date.month, date.day);
                if (_events[key] == null) {
                  _events[key] = [];
                }
                _events[key]!.add({
                  'id': item['id'],
                  'title': item['title'] ?? '',
                  'subtitle': item['location'] ?? item['event_time'] ?? '',
                  'location': item['location'] ?? '',
                  'event_time': item['event_time'] ?? '',
                  'type': 'حدث',
                  'color': Colors.blue,
                });
              }
            }
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading calendar events: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  Future<void> _showAddEventDialog() async {
    final titleController = TextEditingController();
    final locationController = TextEditingController();
    final timeController = TextEditingController();
    DateTime selectedDate = _selectedDay ?? DateTime.now();

    final isAr = AppSettings.language.value == 'ar';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Directionality(
          textDirection: ui.TextDirection.rtl,
          child: AlertDialog(
            title: Text(isAr ? 'إضافة حدث جديد' : 'Add New Event', style: const TextStyle(fontFamily: 'Noto Sans Arabic')),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: isAr ? 'عنوان الحدث *' : 'Event Title *',
                      labelStyle: const TextStyle(fontFamily: 'Noto Sans Arabic'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: locationController,
                    decoration: InputDecoration(
                      labelText: isAr ? 'الموقع / الوصف' : 'Location / Description',
                      labelStyle: const TextStyle(fontFamily: 'Noto Sans Arabic'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: timeController,
                    decoration: InputDecoration(
                      labelText: isAr ? 'الوقت (اختياري)' : 'Time (Optional)',
                      labelStyle: const TextStyle(fontFamily: 'Noto Sans Arabic'),
                      hintText: 'مثال: 10:00 AM',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(isAr ? 'التاريخ: ' : 'Date: '),
                      const Spacer(),
                      TextButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (date != null) {
                            setDialogState(() {
                              selectedDate = date;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(isAr ? 'إلغاء' : 'Cancel', style: const TextStyle(fontFamily: 'Noto Sans Arabic')),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.trim().isEmpty) return;

                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFFFFCC00)))),
                  );

                  final result = await _affairsServices.addCalendarEvent({
                    'title': titleController.text.trim(),
                    'location': locationController.text.trim(),
                    'event_time': timeController.text.trim(),
                    'event_date': DateFormat('yyyy-MM-dd').format(selectedDate),
                  });

                  if (mounted) {
                    Navigator.pop(context); // Pop loading
                    if (result != null) {
                      _loadEvents();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isAr ? 'تم إضافة الحدث بنجاح ✓' : 'Event added successfully ✓', style: const TextStyle(fontFamily: 'Noto Sans Arabic')),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFCC00)),
                child: Text(isAr ? 'حفظ' : 'Save', style: const TextStyle(fontFamily: 'Noto Sans Arabic', color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEditEventDialog(Map<String, dynamic> event) async {
    final titleController = TextEditingController(text: event['title']);
    final locationController = TextEditingController(text: event['location']);
    final timeController = TextEditingController(text: event['event_time']);
    DateTime selectedDate = event['date'] ?? DateTime.now();

    final isAr = AppSettings.language.value == 'ar';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Directionality(
          textDirection: ui.TextDirection.rtl,
          child: AlertDialog(
            title: Text(isAr ? 'تعديل الحدث' : 'Edit Event', style: const TextStyle(fontFamily: 'Noto Sans Arabic')),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: isAr ? 'عنوان الحدث *' : 'Event Title *',
                      labelStyle: const TextStyle(fontFamily: 'Noto Sans Arabic'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: locationController,
                    decoration: InputDecoration(
                      labelText: isAr ? 'الموقع / الوصف' : 'Location / Description',
                      labelStyle: const TextStyle(fontFamily: 'Noto Sans Arabic'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: timeController,
                    decoration: InputDecoration(
                      labelText: isAr ? 'الوقت (اختياري)' : 'Time (Optional)',
                      labelStyle: const TextStyle(fontFamily: 'Noto Sans Arabic'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(isAr ? 'التاريخ: ' : 'Date: '),
                      const Spacer(),
                      TextButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (date != null) {
                            setDialogState(() {
                              selectedDate = date;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(isAr ? 'إلغاء' : 'Cancel', style: const TextStyle(fontFamily: 'Noto Sans Arabic')),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.trim().isEmpty) return;

                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFFFFCC00)))),
                  );

                  final result = await _affairsServices.updateCalendarEvent(event['id'], {
                    'title': titleController.text.trim(),
                    'location': locationController.text.trim(),
                    'event_time': timeController.text.trim(),
                    'event_date': DateFormat('yyyy-MM-dd').format(selectedDate),
                  });

                  if (mounted) {
                    Navigator.pop(context); // Pop loading
                    if (result != null) {
                      _loadEvents();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isAr ? 'تم تعديل الحدث بنجاح ✓' : 'Event updated successfully ✓', style: const TextStyle(fontFamily: 'Noto Sans Arabic')),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFCC00)),
                child: Text(isAr ? 'حفظ' : 'Save', style: const TextStyle(fontFamily: 'Noto Sans Arabic', color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleDeleteEvent(int eventId) async {
    final isAr = AppSettings.language.value == 'ar';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: Text(isAr ? 'حذف الحدث' : 'Delete Event', style: const TextStyle(fontFamily: 'Noto Sans Arabic')),
          content: Text(isAr ? 'هل أنت متأكد من حذف هذا الحدث؟' : 'Are you sure you want to delete this event?', style: const TextStyle(fontFamily: 'Noto Sans Arabic')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(isAr ? 'إلغاء' : 'Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(isAr ? 'حذف' : 'Delete', style: const TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFFFFCC00)))),
    );

    final success = await _affairsServices.deleteCalendarEvent(eventId);

    if (mounted) {
      Navigator.pop(context); // Pop loading
      if (success) {
        _loadEvents();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? 'تم حذف الحدث بنجاح ✓' : 'Event deleted successfully ✓', style: const TextStyle(fontFamily: 'Noto Sans Arabic')),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor   = isDark ? const Color(0xFF121212) : const Color(0xFFF9F9F9);
    final Color cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subColor  = isDark ? Colors.grey.shade400 : Colors.grey;

    final isAr = AppSettings.language.value == 'ar';

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 90),
          child: FloatingActionButton(
            onPressed: _showAddEventDialog,
            backgroundColor: const Color(0xFFFFCC00),
            foregroundColor: Colors.black,
            child: const Icon(Icons.add, size: 28),
          ),
        ),
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  // الهيدر
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: Icon(Icons.settings, color: textColor, size: 26),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SettingsScreen()),
                              ).then((_) => _loadEvents());
                            },
                          ),
                        ),
                        Text(
                          isAr ? "التقويم الأكاديمي" : "Academic Calendar",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            fontFamily: 'Noto Sans Arabic',
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: Icon(Icons.arrow_back, color: textColor, size: 26),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // المحتوى
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFCC00)),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadEvents,
                            color: const Color(0xFFFFCC00),
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 10, 16, 140),
                              children: [
                                // بطاقة التقويم
                                Container(
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(isDark ? 30 : 8),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: TableCalendar(
                                    locale: isAr ? 'ar' : 'en_US',
                                    firstDay: DateTime.utc(2020, 10, 16),
                                    lastDay: DateTime.utc(2030, 3, 14),
                                    focusedDay: _focusedDay,
                                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                                    onDaySelected: (selectedDay, focusedDay) {
                                      setState(() {
                                        _selectedDay = selectedDay;
                                        _focusedDay = focusedDay;
                                      });
                                    },
                                    eventLoader: _getEventsForDay,
                                    headerStyle: HeaderStyle(
                                      formatButtonVisible: false,
                                      titleCentered: true,
                                      titleTextStyle: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Noto Sans Arabic'),
                                      leftChevronIcon: Icon(Icons.chevron_left, color: textColor),
                                      rightChevronIcon: Icon(Icons.chevron_right, color: textColor),
                                    ),
                                    calendarStyle: CalendarStyle(
                                      defaultTextStyle: TextStyle(color: textColor),
                                      weekendTextStyle: TextStyle(color: textColor.withOpacity(0.6)),
                                      todayDecoration: BoxDecoration(
                                        color: const Color(0xFFFFCC00).withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      todayTextStyle: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                                      selectedDecoration: const BoxDecoration(
                                        color: Color(0xFFFFCC00),
                                        shape: BoxShape.circle,
                                      ),
                                      selectedTextStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                      markerDecoration: const BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // عنوان "أحداث الشهر"
                                Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFCC00),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      isAr ? "أحداث الشهر" : "Monthly Events",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                        fontFamily: 'Noto Sans Arabic',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // قائمة الأحداث
                                ..._buildEventList(cardColor, textColor, subColor),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),

            // شريط السفلي
            CustomBottomNav(
              currentIndex: 0,
              centerButton: AffairsOfficerSpeedDial(),
              onHomeTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AffairsOfficerHomeScreen()),
                );
              },
              onProfileTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AffairsOfficerProfileScreen()),
                );
              },
              onNotificationsTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AffairsOfficerNotificationsScreen()),
                );
              },
              onMessagesTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AffairsOfficerMessagesScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildEventList(Color cardColor, Color textColor, Color subColor) {
    List<Map<String, dynamic>> allEvents = [];
    _events.forEach((date, events) {
      for (var event in events) {
        allEvents.add({
          ...event,
          'date': date,
        });
      }
    });

    allEvents.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    if (allEvents.isEmpty) {
      return [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Text(
              AppSettings.language.value == 'ar' ? "لا توجد أحداث هذا الشهر" : "No events this month",
              style: TextStyle(color: subColor, fontSize: 14),
            ),
          ),
        )
      ];
    }

    return allEvents.map((event) {
      final DateTime date = event['date'];
      final String dayName = DateFormat('EEEE', AppSettings.language.value == 'ar' ? 'ar' : 'en_US').format(date);
      final int dayNumber = date.day;
      final Color eventColor = event['color'] as Color;

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // التاريخ (يمين)
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: eventColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dayName,
                      style: TextStyle(
                        fontSize: 10,
                        color: eventColor,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Noto Sans Arabic',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$dayNumber',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: eventColor,
                        fontFamily: 'Noto Sans Arabic',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // المحتوى (وسط)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: eventColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          event['type'],
                          style: TextStyle(
                            fontSize: 12,
                            color: eventColor,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Noto Sans Arabic',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      event['title'],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        fontFamily: 'Noto Sans Arabic',
                      ),
                    ),
                    if (event['subtitle'].toString().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        event['subtitle'],
                        style: TextStyle(
                          fontSize: 12,
                          color: subColor,
                          height: 1.4,
                          fontFamily: 'Noto Sans Arabic',
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // تعديل وحذف (يسار)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.amber, size: 20),
                    onPressed: () => _showEditEventDialog(event),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    onPressed: () => _handleDeleteEvent(event['id']),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}