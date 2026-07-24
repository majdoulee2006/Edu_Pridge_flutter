import 'dart:io';

void main() {
  var dir = Directory('lib/screens');
  var files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.contains('message') && f.path.endsWith('.dart'));
  
  for (var file in files) {
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
}
