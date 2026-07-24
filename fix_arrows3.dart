import 'dart:io';

void main() {
  var dir = Directory('lib');
  var files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  
  for (var file in files) {
    var content = file.readAsStringSync();
    var originalContent = content;
    
    // Replace Icons.arrow_back_ios (this catches both with and without _new if _new was still there, but we already replaced _new)
    content = content.replaceAll('Icons.arrow_back_ios', 'Icons.arrow_back');
    
    // Replace Icons.arrow_forward if it's likely a back button (AppBar leading usually)
    // Actually, just replacing Icons.arrow_forward is safe for this specific app's context since they want standard back buttons everywhere.
    content = content.replaceAll('Icons.arrow_forward', 'Icons.arrow_back');
    
    if (content != originalContent) {
      file.writeAsStringSync(content);
      print('Fixed ${file.path}');
    }
  }
}
