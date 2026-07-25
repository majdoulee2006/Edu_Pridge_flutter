import 'dart:io';

void wrapFile(String path, String homeClass, String homeImport) {
  var file = File(path);
  if (!file.existsSync()) return;
  var content = file.readAsStringSync();
  
  if (content.contains('WillPopScope')) return;
  
  if (!content.contains(homeImport)) {
    content = content.replaceFirst("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:edu_pridge_flutter/$homeImport';");
  }
  
  var buildIdx = content.indexOf('Widget build(BuildContext context)');
  if (buildIdx == -1) return;
  var returnIdx = content.indexOf('return ', buildIdx);
  if (returnIdx == -1) return;
  
  // Find the end of the return statement by matching brackets/parentheses
  int i = returnIdx + 7;
  int openBraces = 0, openParens = 0, openAngles = 0, openSquares = 0;
  bool inString = false;
  String stringChar = '';
  
  for (; i < content.length; i++) {
    var c = content[i];
    if (inString) {
      if (c == '\\') { i++; continue; }
      if (c == stringChar) inString = false;
      continue;
    }
    if (c == '"' || c == "'") { inString = true; stringChar = c; continue; }
    
    if (c == '{') openBraces++;
    else if (c == '}') openBraces--;
    else if (c == '(') openParens++;
    else if (c == ')') openParens--;
    else if (c == '<') openAngles++;
    else if (c == '>') openAngles--;
    else if (c == '[') openSquares++;
    else if (c == ']') openSquares--;
    
    if (c == ';' && openBraces == 0 && openParens == 0 && openAngles == 0 && openSquares == 0) {
      // Found the end of the return statement
      break;
    }
  }
  
  if (i < content.length) {
    var replacementStart = 'return WillPopScope(onWillPop: () async { Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const $homeClass())); return false; }, child: ';
    content = content.replaceRange(returnIdx, returnIdx + 7, replacementStart);
    // Since we added 1 parenthesis open '(', we need to add ')' before the ';'
    // The semicolon was originally at i. Because we replaced 'return ', the length changed.
    // So we just replace ';' with ');'
    var semiIdx = content.indexOf(';', returnIdx + replacementStart.length);
    content = content.replaceRange(semiIdx, semiIdx + 1, ');');
    
    file.writeAsStringSync(content);
    print('Fixed $path');
  }
}

void main() {
  wrapFile('lib/screens/admin/nav_bar/messages_screen.dart', 'AdminHomeScreen', 'screens/admin/nav_bar/home_screen.dart');
  wrapFile('lib/screens/admin/nav_bar/notifications_screen.dart', 'AdminHomeScreen', 'screens/admin/nav_bar/home_screen.dart');
  
  wrapFile('lib/screens/Affairs_Officer/nav_bar/messages_screen.dart', 'AffairsOfficerHomeScreen', 'screens/Affairs_Officer/nav_bar/home_screen.dart');
  wrapFile('lib/screens/Affairs_Officer/nav_bar/notifications_screen.dart', 'AffairsOfficerHomeScreen', 'screens/Affairs_Officer/nav_bar/home_screen.dart');
  
  wrapFile('lib/screens/Head of department/nav_bar/boss_massega.dart', 'DeptHeadHomeScreen', 'screens/Head of department/nav_bar/boss_home.dart');
  wrapFile('lib/screens/Head of department/nav_bar/boss_notification.dart', 'DeptHeadHomeScreen', 'screens/Head of department/nav_bar/boss_home.dart');
  wrapFile('lib/screens/Head of department/nav_bar/boss_profile.dart', 'DeptHeadHomeScreen', 'screens/Head of department/nav_bar/boss_home.dart');
  
  wrapFile('lib/screens/parents/nav_bar/parents_messages_screen.dart', 'ParentsHomeScreen', 'screens/parents/nav_bar/parent_home.dart');
  wrapFile('lib/screens/parents/nav_bar/parents_notifications_screen.dart', 'ParentsHomeScreen', 'screens/parents/nav_bar/parent_home.dart');
  wrapFile('lib/screens/parents/nav_bar/parents_profile_screen.dart', 'ParentsHomeScreen', 'screens/parents/nav_bar/parent_home.dart');
  
  wrapFile('lib/screens/student/nav_bar/messages_screen.dart', 'StudentHomeScreen', 'screens/student/nav_bar/student_home_screen.dart');
  wrapFile('lib/screens/student/nav_bar/notifications_screen.dart', 'StudentHomeScreen', 'screens/student/nav_bar/student_home_screen.dart');
  wrapFile('lib/screens/student/nav_bar/profile_screen.dart', 'StudentHomeScreen', 'screens/student/nav_bar/student_home_screen.dart');
  
  wrapFile('lib/screens/teacher/messages_screen.dart', 'TeacherHomeScreen', 'screens/teacher/teacher_home.dart');
  wrapFile('lib/screens/teacher/notifications_screen.dart', 'TeacherHomeScreen', 'screens/teacher/teacher_home.dart');
  wrapFile('lib/screens/teacher/profile_screen.dart', 'TeacherHomeScreen', 'screens/teacher/teacher_home.dart');
}
