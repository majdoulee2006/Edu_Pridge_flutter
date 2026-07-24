import 'dart:io';

void main() {
  var dir = Directory('lib');
  var files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  
  for (var file in files) {
    var content = file.readAsStringSync();
    var originalContent = content;
    
    content = content.replaceAll("'https://i.pravatar.cc/150'", "''");
    content = content.replaceAll('"https://i.pravatar.cc/150"', "''");
    
    if (content != originalContent) {
      file.writeAsStringSync(content);
      print('Fixed ${file.path}');
    }
  }
}
