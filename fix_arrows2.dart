import 'dart:io';

void main() {
  var dir = Directory('lib');
  var files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  
  for (var file in files) {
    var content = file.readAsStringSync();
    var newContent = content.replaceAll(
      'Icons.arrow_back_ios_new',
      'Icons.arrow_back'
    );
    
    if (content != newContent) {
      file.writeAsStringSync(newContent);
      print('Fixed ${file.path}');
    }
  }
}
