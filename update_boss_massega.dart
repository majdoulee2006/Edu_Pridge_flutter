import 'dart:io';

void main() {
  var file = File('lib/screens/Head of department/nav_bar/boss_massega.dart');
  
  var content = file.readAsStringSync();
  
  var filterLogic = '''
                                final allContacts = chatService.contacts;
                                final dynamicContacts = allContacts.where((c) {
                                  return c['role'] == 'Administration' || (c['last_message'] != null && c['last_message'].toString().trim().isNotEmpty);
                                }).toList();
''';

  content = content.replaceFirst(
    'final dynamicContacts = chatService.contacts;',
    filterLogic
  );

  file.writeAsStringSync(content);
  print('Updated ${file.path}');
}
