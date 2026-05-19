import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'announcement_setter_page.dart';

class AnnouncementCalendarPage extends StatefulWidget {
  final String? initialAnnouncementId;

  const AnnouncementCalendarPage({
    super.key,
    this.initialAnnouncementId,
  });

  @override
  State<AnnouncementCalendarPage> createState() => _AnnouncementCalendarPageState();
}

class _AnnouncementCalendarPageState extends State<AnnouncementCalendarPage> {
  final ScrollController dateScrollController = ScrollController();
  PageController announcementPageController = PageController(viewportFraction: 0.82);

  String? selectedDateKey;
  int selectedAnnouncementIndex = 0;

  final double dateItemWidth = 62;
  final double dateItemSpacing = 10;

  double get dateItemExtent => dateItemWidth + dateItemSpacing;

  @override
  void dispose() {
    dateScrollController.dispose();
    announcementPageController.dispose();
    super.dispose();
  }

  DateTime getDateTime(QueryDocumentSnapshot announcement) {
    final data = announcement.data() as Map<String, dynamic>;
    final timestamp = data['createdAt'];

    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }

    return DateTime.now();
  }

  String getDateKey(DateTime date) {
    String month = date.month.toString().padLeft(2, '0');
    String day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  String getMonthShort(DateTime date) {
    List<String> months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];

    return months[date.month - 1];
  }

  String formatLongDate(DateTime date) {
    List<String> months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    int hour = date.hour;
    String minute = date.minute.toString().padLeft(2, '0');
    String amPm = hour >= 12 ? 'PM' : 'AM';

    if (hour > 12) {
      hour = hour - 12;
    }

    if (hour == 0) {
      hour = 12;
    }

    return '${months[date.month - 1]} ${date.day}, ${date.year}   $hour:$minute $amPm';
  }

  String limitText(String text) {
    if (text.length <= 34) {
      return text;
    }

    return '${text.substring(0, 34).trimRight()}...';
  }

  String getCategory(QueryDocumentSnapshot announcement) {
    final data = announcement.data() as Map<String, dynamic>;
    return data['category'] ?? data['type'] ?? 'Events';
  }

  String getTitle(QueryDocumentSnapshot announcement) {
    final data = announcement.data() as Map<String, dynamic>;
    return data['title'] ?? 'No title';
  }

  String getDetails(QueryDocumentSnapshot announcement) {
    final data = announcement.data() as Map<String, dynamic>;
    return data['details'] ?? 'No details';
  }

  void centerSelectedDate(List<String> dateKeys) {
    if (selectedDateKey == null) {
      return;
    }

    int selectedIndex = dateKeys.indexOf(selectedDateKey!);

    if (selectedIndex < 0 || !dateScrollController.hasClients) {
      return;
    }

    double targetOffset = selectedIndex * dateItemExtent;
    double maxScroll = dateScrollController.position.maxScrollExtent;

    if (targetOffset < 0) {
      targetOffset = 0;
    }

    if (targetOffset > maxScroll) {
      targetOffset = maxScroll;
    }

    dateScrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void selectDate(
    String dateKey,
    List<String> dateKeys, {
    int announcementIndex = 0,
  }) {
    if (selectedDateKey == dateKey) {
      setState(() {
        selectedAnnouncementIndex = announcementIndex;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        centerSelectedDate(dateKeys);

        if (announcementPageController.hasClients) {
          announcementPageController.animateToPage(
            announcementIndex,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });

      return;
    }

    final oldController = announcementPageController;

    setState(() {
      selectedDateKey = dateKey;
      selectedAnnouncementIndex = announcementIndex;
      announcementPageController = PageController(
        viewportFraction: 0.82,
        initialPage: announcementIndex,
      );
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      oldController.dispose();
      centerSelectedDate(dateKeys);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('announcements')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Text('Error loading announcements'),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final announcements = snapshot.data!.docs;

            if (announcements.isEmpty) {
              return emptyCalendarPage();
            }

            final Map<String, List<QueryDocumentSnapshot>> groupedAnnouncements = {};

            for (var announcement in announcements) {
              DateTime date = getDateTime(announcement);
              String dateKey = getDateKey(date);

              if (!groupedAnnouncements.containsKey(dateKey)) {
                groupedAnnouncements[dateKey] = [];
              }

              groupedAnnouncements[dateKey]!.add(announcement);
            }

            final dateKeys = groupedAnnouncements.keys.toList();

            dateKeys.sort((a, b) {
              DateTime dateA = DateTime.parse(a);
              DateTime dateB = DateTime.parse(b);
              return dateA.compareTo(dateB);
            });

            if (selectedDateKey == null) {
              QueryDocumentSnapshot initialAnnouncement = announcements.first;
              int initialIndexOnDate = 0;

              if (widget.initialAnnouncementId != null) {
                for (var announcement in announcements) {
                  if (announcement.id == widget.initialAnnouncementId) {
                    initialAnnouncement = announcement;
                    break;
                  }
                }
              }

              selectedDateKey = getDateKey(getDateTime(initialAnnouncement));

              final selectedDateAnnouncements = groupedAnnouncements[selectedDateKey!] ?? [];
              initialIndexOnDate = selectedDateAnnouncements.indexWhere((announcement) {
                return announcement.id == initialAnnouncement.id;
              });

              if (initialIndexOnDate < 0) {
                initialIndexOnDate = 0;
              }

              selectedAnnouncementIndex = initialIndexOnDate;

              announcementPageController = PageController(
                viewportFraction: 0.82,
                initialPage: initialIndexOnDate,
              );

              WidgetsBinding.instance.addPostFrameCallback((_) {
                centerSelectedDate(dateKeys);
              });
            }

            if (!dateKeys.contains(selectedDateKey)) {
              selectedDateKey = dateKeys.last;
              selectedAnnouncementIndex = 0;
            }

            final selectedDateAnnouncements = groupedAnnouncements[selectedDateKey!] ?? [];

            if (selectedAnnouncementIndex >= selectedDateAnnouncements.length) {
              selectedAnnouncementIndex = 0;
            }

            final selectedAnnouncement = selectedDateAnnouncements[selectedAnnouncementIndex];
            final selectedCategory = getCategory(selectedAnnouncement);

            final otherAnnouncements = announcements.where((announcement) {
              return announcement.id != selectedAnnouncement.id;
            }).toList();

            otherAnnouncements.sort((a, b) {
              DateTime selectedDate = DateTime.parse(selectedDateKey!);
              DateTime dateA = getDateTime(a);
              DateTime dateB = getDateTime(b);

              int differenceA = dateA.difference(selectedDate).inDays.abs();
              int differenceB = dateB.difference(selectedDate).inDays.abs();

              return differenceA.compareTo(differenceB);
            });

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          const CircleAvatar(
                            backgroundColor: Colors.white,
                            child: Icon(Icons.notifications_none, color: Colors.black),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      Center(
                        child: Container(
                          width: 170,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xffFFCB45),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Text(
                            "WHAT’S NEW",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      SizedBox(
                        height: 75,
                        child: ListView.builder(
                          controller: dateScrollController,
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.symmetric(
                            horizontal: ((MediaQuery.of(context).size.width - dateItemWidth) / 2).clamp(0, double.infinity).toDouble(),
                          ),
                          itemCount: dateKeys.length,
                          itemBuilder: (context, index) {
                            final dateKey = dateKeys[index];
                            final date = DateTime.parse(dateKey);
                            final selected = dateKey == selectedDateKey;

                            return GestureDetector(
                              onTap: () {
                                selectDate(dateKey, dateKeys);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                width: dateItemWidth,
                                height: selected ? 68 : 58,
                                margin: EdgeInsets.only(right: dateItemSpacing),
                                decoration: BoxDecoration(
                                  color: selected ? Colors.black : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 5,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      getMonthShort(date),
                                      style: TextStyle(
                                        color: selected ? Colors.white : Colors.grey,
                                        fontSize: selected ? 12 : 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      date.day.toString(),
                                      style: TextStyle(
                                        color: selected ? Colors.white : Colors.grey,
                                        fontSize: selected ? 22 : 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 18),

                      Center(
                        child: categoryHeader(selectedCategory),
                      ),

                      const SizedBox(height: 12),

                      SizedBox(
                        height: 285,
                        child: PageView.builder(
                          key: ValueKey(selectedDateKey),
                          controller: announcementPageController,
                          padEnds: true,
                          itemCount: selectedDateAnnouncements.length,
                          onPageChanged: (index) {
                            setState(() {
                              selectedAnnouncementIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            return announcementDetailCard(
                              selectedDateAnnouncements[index],
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 14),

                      if (selectedDateAnnouncements.length > 1)
                        Center(
                          child: Text(
                            '${selectedAnnouncementIndex + 1} of ${selectedDateAnnouncements.length}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                      const SizedBox(height: 12),

                      Container(
                        height: 1,
                        color: Colors.grey.shade400,
                      ),

                      const SizedBox(height: 14),

                      const Text(
                        "Recent Updates",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 10),

                      SizedBox(
                        height: 230,
                        child: otherAnnouncements.isEmpty
                            ? const Center(
                          child: Text(
                            "No other announcements.",
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                            : ListView.builder(
                          itemCount: otherAnnouncements.length,
                          itemBuilder: (context, index) {
                            final announcement = otherAnnouncements[index];

                            return smallAnnouncementRow(
                              announcement,
                              onTap: () {
                                String dateKey = getDateKey(getDateTime(announcement));
                                final announcementsOnDate = groupedAnnouncements[dateKey] ?? [];

                                int newIndex = announcementsOnDate.indexWhere((item) {
                                  return item.id == announcement.id;
                                });

                                if (newIndex < 0) {
                                  newIndex = 0;
                                }

                                selectDate(
                                  dateKey,
                                  dateKeys,
                                  announcementIndex: newIndex,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                bottomNavigationBar(context),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget emptyCalendarPage() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.notifications_none, color: Colors.black),
                  ),
                ],
              ),
              const SizedBox(height: 80),
              Center(
                child: Container(
                  width: 170,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xffFFCB45),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    "WHAT’S NEW",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const Center(
                child: Text(
                  "No announcements yet.",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar(context),
      ],
    );
  }

  Widget announcementDetailCard(QueryDocumentSnapshot announcement) {
    final title = getTitle(announcement);
    final details = getDetails(announcement);
    final category = getCategory(announcement);
    final date = getDateTime(announcement);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: getColor(category),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            formatLongDate(date),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    details,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget smallAnnouncementRow(
      QueryDocumentSnapshot announcement, {
        required VoidCallback onTap,
      }) {
    final title = getTitle(announcement);
    final details = getDetails(announcement);
    final category = getCategory(announcement);
    final date = formatLongDate(getDateTime(announcement));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: getColor(category), width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: getColor(category),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                getIcon(category),
                size: 28,
                color: getCategoryBadgeColor(category),
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    date,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    limitText(details),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 9),
                  ),
                ],
              ),
            ),

            const Icon(Icons.arrow_forward_ios, size: 17),
          ],
        ),
      ),
    );
  }

  Widget categoryHeader(String category) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          getIcon(category),
          size: 16,
          color: getCategoryBadgeColor(category),
        ),
        const SizedBox(width: 6),
        Text(
          "$category Announcement",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: getCategoryTextColor(category),
          ),
        ),
      ],
    );
  }

  Widget bottomNavigationBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(35),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          bottomIcon(
            Icons.home,
            false,
            onTap: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
          ),
          bottomIcon(Icons.calendar_month, true),
          bottomIcon(
            Icons.chat_bubble_outline,
            false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AnnouncementSetterPage(),
                ),
              );
            },
          ),
          bottomIcon(Icons.person_outline, false),
        ],
      ),
    );
  }

  Widget bottomIcon(IconData icon, bool selected, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.black,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: selected ? Colors.black : Colors.white,
        ),
      ),
    );
  }

  IconData getIcon(String type) {
    if (type == "Academics") {
      return Icons.school;
    } else if (type == "Organization") {
      return Icons.groups;
    } else if (type == "Urgent") {
      return Icons.warning;
    } else if (type == "Campus Updates") {
      return Icons.campaign;
    } else {
      return Icons.event;
    }
  }

  Color getColor(String type) {
    if (type == "Academics") {
      return Colors.blue.shade100;
    } else if (type == "Organization") {
      return Colors.orange.shade100;
    } else if (type == "Urgent") {
      return Colors.red.shade100;
    } else if (type == "Campus Updates") {
      return Colors.green.shade100;
    } else {
      return Colors.purple.shade100;
    }
  }

  Color getCategoryBadgeColor(String type) {
    if (type == "Academics") {
      return Colors.blue;
    } else if (type == "Organization") {
      return Colors.orange;
    } else if (type == "Urgent") {
      return Colors.red;
    } else if (type == "Campus Updates") {
      return Colors.green;
    } else {
      return Colors.purple;
    }
  }

  Color getCategoryTextColor(String type) {
    if (type == "Academics") {
      return Colors.blue.shade900;
    } else if (type == "Organization") {
      return Colors.orange.shade900;
    } else if (type == "Urgent") {
      return Colors.red.shade900;
    } else if (type == "Campus Updates") {
      return Colors.green.shade900;
    } else {
      return Colors.purple.shade900;
    }
  }
}