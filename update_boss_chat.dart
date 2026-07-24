import 'dart:io';

void main() {
  var file = File('lib/screens/Head of department/nav_bar/boss_massega.dart'); // typo in file name
  if (!file.existsSync()) {
    print('File not found');
    return;
  }
  
  var content = file.readAsStringSync();
  
  // We need to change the ListView.builder to only show active chats or Admin
  // The dynamicContacts list needs filtering:
  var filterLogic = '''
                                final allContacts = chatService.contacts;
                                final activeContacts = allContacts.where((c) {
                                  return c['role'] == 'Administration' || (c['last_message'] != null && c['last_message'].toString().trim().isNotEmpty);
                                }).toList();
                                
                                if (activeContacts.isEmpty) {
                                  return const Center(child: Text('?? ???? ??????? ????'));
                                }

                                return ListView.builder(
                                  itemCount: activeContacts.length,
                                  itemBuilder: (context, index) {
                                    final contact = activeContacts[index];
''';

  content = content.replaceAll(
    '''
                                final dynamicContacts = chatService.contacts;
                                
                                if (dynamicContacts.isEmpty) {
                                  return const Center(child: Text('?? ???? ???? ?????'));
                                }

                                return ListView.builder(
                                  itemCount: dynamicContacts.length,
                                  itemBuilder: (context, index) {
                                    final contact = dynamicContacts[index];
''', 
    filterLogic
  );
  
  content = content.replaceAll(
    "final dynamicContacts = chatService.contacts;\n                                \n                                if (dynamicContacts.isEmpty) {\n                                  return const Center(child: Text('?? ???? ???? ?????'));\n                                }\n\n                                return ListView.builder(\n                                  itemCount: dynamicContacts.length,\n                                  itemBuilder: (context, index) {\n                                    final contact = dynamicContacts[index];",
    filterLogic
  );

  // Add FAB
  var fabCode = '''
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show search dialog or screen
          _showNewChatDialog(context, chatService.contacts, isDark, cardColor, textColor);
        },
        backgroundColor: const Color(0xFFFFCC00),
        child: const Icon(Icons.add, color: Colors.black),
      ),
      bottomNavigationBar: CustomBottomNav(
''';
  
  // Wait, bottom navigation bar is in a Stack:
  // Instead of floatingActionButton on Scaffold, we can add it to Scaffold properties.
  // BossMessageScreen uses Stack inside Scaffold body...
  // Let's replace Scaffold with added FAB.
  if (content.contains('backgroundColor: bgColor,')) {
    content = content.replaceFirst('backgroundColor: bgColor,', 'backgroundColor: bgColor,\n' + fabCode.split('bottomNavigationBar')[0]);
  }
  
  // Add dialog function
  var dialogFunc = '''
  void _showNewChatDialog(BuildContext context, List<Map<String, dynamic>> allContacts, bool isDark, Color cardColor, Color textColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('??? ?????? ?????', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: controller,
                      itemCount: allContacts.length,
                      itemBuilder: (context, index) {
                        final contact = allContacts[index];
                        return _buildChatTile(context, contact, isDark, cardColor, textColor);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildChatTile(
''';
  
  content = content.replaceFirst('  Widget _buildChatTile(', dialogFunc);

  file.writeAsStringSync(content);
  print('Updated boss_massega.dart');
}
