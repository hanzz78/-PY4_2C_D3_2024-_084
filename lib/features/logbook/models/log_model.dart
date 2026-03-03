import 'package:mongo_dart/mongo_dart.dart';

class LogModel {
  final ObjectId id; // Menggunakan ObjectId sesuai standar MongoDB
  final String title;
  final String date;
  final String description;
  final String category;

  LogModel({
    required this.id,
    required this.title,
    required this.date,
    required this.description,
    required this.category,
  });

  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      id: map['_id'] as ObjectId,
      title: map['title'],
      date: map['date'],
      description: map['description'],
      category: map['category'] ??'Pribadi',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'date': date,
      'description': description,
      'category' : category,
    };
  }
}
