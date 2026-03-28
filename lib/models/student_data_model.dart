class StudentDashboardModel {
  final String name;
  final String level;
  final double gpa;
  final Map<String, dynamic> upcomingLecture;

  StudentDashboardModel({
    required this.name,
    required this.level,
    required this.gpa,
    required this.upcomingLecture,
  });

  // دالة التحويل من JSON إلى Object
  factory StudentDashboardModel.fromJson(Map<String, dynamic> json) {
    return StudentDashboardModel(
      name: json['student_name'],
      level: json['level'],
      gpa: json['gpa'].toDouble(),
      upcomingLecture: json['upcoming_lecture'],
    );
  }
}