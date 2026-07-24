import 'dart:io';

void main() {
  var dir = Directory('lib');
  var files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  
  for (var file in files) {
    var content = file.readAsStringSync();
    var newContent = content.replaceAll(
      'isAr ? Icons.arrow_forward : Icons.arrow_back', 
      'Icons.arrow_back_ios_new'
    ).replaceAll(
      'isAr ? Icons.arrow_back_ios_new_rounded : Icons.arrow_forward_ios_rounded',
      'Icons.arrow_back_ios_new'
    ).replaceAll(
      'Icon(Icons.arrow_forward,',
      'Icon(Icons.arrow_back_ios_new,'
    ).replaceAll(
      'const Icon(Icons.arrow_forward,',
      'const Icon(Icons.arrow_back_ios_new,'
    ).replaceAll(
      'Icon(Icons.arrow_forward_ios_rounded,',
      'Icon(Icons.arrow_back_ios_new,'
    ).replaceAll(
      'const Icon(Icons.arrow_forward_ios_rounded,',
      'const Icon(Icons.arrow_back_ios_new,'
    );
    
    if (content != newContent) {
      file.writeAsStringSync(newContent);
      print('Fixed ${file.path}');
    }
  }
}
