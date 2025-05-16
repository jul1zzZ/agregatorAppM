import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String senderEmail;
  final String text;
  final DateTime? timestamp;

  Message({
    required this.senderEmail,
    required this.text,
    this.timestamp,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      senderEmail: map['senderEmail'] ?? '',
      text: map['text'] ?? '',
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderEmail': senderEmail,
      'text': text,
      'timestamp': timestamp != null ? Timestamp.fromDate(timestamp!) : null,
    };
  }
}
