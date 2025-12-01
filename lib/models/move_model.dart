import 'package:cloud_firestore/cloud_firestore.dart';

class MoveModel {
  final String id;
  final String title;
  final String link;
  final String submittedByUid;
  final int round;
  final DateTime submittedAt;
  final Map<String, int> votes; // Key = UserID, Value = Score (1-10)

  MoveModel({
    required this.id,
    required this.title,
    required this.link,
    required this.submittedByUid,
    required this.round,
    required this.submittedAt,
    this.votes = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'link': link,
      'submittedByUid': submittedByUid,
      'round': round,
      'submittedAt': Timestamp.fromDate(submittedAt), 
      'votes': votes, 
    };
  }

  factory MoveModel.fromMap(Map<String, dynamic> map, String id) { 
    DateTime parseDate(dynamic date) {
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.parse(date);
      return DateTime.now(); 
    }
    
    Map<String, int> parsedVotes = {};
    if (map['votes'] != null) {
      Map<String, dynamic> rawVotes = map['votes'] as Map<String, dynamic>;
      rawVotes.forEach((key, value) {
        parsedVotes[key] = (value as num).toInt();
      });
    }

    return MoveModel(
      id: id, 
      title: map['title'] as String? ?? 'Untitled Move',
      link: map['link'] as String? ?? '',
      submittedByUid: map['submittedByUid'] as String? ?? map['userId'] as String? ?? 'unknown',
      round: map['round'] as int? ?? 1,
      submittedAt: parseDate(map['submittedAt'] ?? map['timestamp']),
      votes: parsedVotes,
    );
  }
  
  int get totalScore {
    if (votes.isEmpty) return 0;
    return votes.values.reduce((a, b) => a + b);
  }
}