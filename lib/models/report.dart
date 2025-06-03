/*
*
* models of a report
*
* -----------------------------------------
*
* A report is made with
*
* - id
* - numberId
* - userId
* - reason
* - reportDate
*
* */

import 'package:cloud_firestore/cloud_firestore.dart';

class Report {
  final String? id;
  final String numberId;
  final String userId;
  final String reason;
  final DateTime reportDate;

  Report({
    this.id,
    required this.numberId,
    required this.userId,
    required this.reason,
    required this.reportDate,
  });

  factory Report.fromMap(Map<String, dynamic> map, String id) {
    return Report(
      id: id,
      numberId: map['number_id'],
      userId: map['user_id'],
      reason: map['reason'],
      reportDate: (map['report_date'] as Timestamp).toDate(),
    );
  }

  factory Report.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Report(
      id: doc.id,
      numberId: data['number_id'],
      userId: data['user_id'],
      reason: data['reason'],
      reportDate: (data['report_date'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'number_id': numberId,
      'user_id': userId,
      'reason': reason,
      'report_date': Timestamp.fromDate(reportDate),
    };
  }
}