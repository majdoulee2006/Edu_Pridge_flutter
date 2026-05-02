class TeacherModel {
  final int id;
  final String name;
  final String subject;
  final bool isOnline;
  final String imageUrl;

  TeacherModel({
    required this.id,
    required this.name,
    required this.subject,
    required this.isOnline,
    required this.imageUrl,
  });

  factory TeacherModel.fromJson(Map<String, dynamic> json) {
    return TeacherModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      subject: json['subject'] ?? '',
      isOnline: json['is_online'] == 1 || json['is_online'] == true,
      imageUrl: json['image_url'] ?? '',
    );
  }
}