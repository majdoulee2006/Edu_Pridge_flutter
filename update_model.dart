import 'dart:io';

void main() {
  var file = File('lib/models/chat_message_model.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceFirst('bool isRead;', 'bool isRead;\n  bool isDelivered;');
  content = content.replaceFirst('this.isRead = false,', 'this.isRead = false,\n    this.isDelivered = false,');
  content = content.replaceFirst("isRead: json['is_read'] == 1 || json['is_read'] == true,", "isRead: json['is_read'] == 1 || json['is_read'] == true,\n      isDelivered: json['is_delivered'] == 1 || json['is_delivered'] == true,");
  
  file.writeAsStringSync(content);
}
