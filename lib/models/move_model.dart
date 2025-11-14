// lib/models/move_model.dart
// --- START COPY & PASTE HERE ---
import 'package:cloud_firestore/cloud_firestore.dart';

class MoveModel {
  final String id;
  final String title;
  final String link;
  final String submittedByUid; // FIX: This is the correct field name
  final int round;
  final DateTime submittedAt;
  final List<String> votes; // FIX: Added votes list

  MoveModel({
    required this.id,
    required this.title,
    required this.link,
    required this.submittedByUid, // FIX: Use submittedByUid
    required this.round,
    required this.submittedAt,
    this.votes = const [],
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
    
    final List<String> votesList = (map['votes'] as List<dynamic>?)
        ?.map((item) => item as String)
        .toList() ?? [];

    return MoveModel(
      id: id, 
      title: map['title'] as String? ?? 'Untitled Move',
      link: map['link'] as String? ?? '',
      // FIX: Read 'submittedByUid' OR the old 'userId' for compatibility
      submittedByUid: map['submittedByUid'] as String? ?? map['userId'] as String? ?? 'unknown',
      round: map['round'] as int? ?? 1,
      submittedAt: parseDate(map['submittedAt'] ?? map['timestamp']), // Handle old field name
      votes: votesList,
    );
  }
}
// --- END COPY & PASTE HERE ---