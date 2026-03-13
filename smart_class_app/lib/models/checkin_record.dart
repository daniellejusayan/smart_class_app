class CheckinRecord {
  final int? id;
  final String studentId;
  final String? checkinTime;
  final double? checkinLatitude;
  final double? checkinLongitude;
  final String? checkinQrValue;
  final String? previousTopic;
  final String? expectedTopic;
  final int? mood;
  final String? checkoutTime;
  final double? checkoutLatitude;
  final double? checkoutLongitude;
  final String? checkoutQrValue;
  final String? learnedToday;
  final String? feedback;
  final bool isCompleted;

  CheckinRecord({
    this.id,
    required this.studentId,
    this.checkinTime,
    this.checkinLatitude,
    this.checkinLongitude,
    this.checkinQrValue,
    this.previousTopic,
    this.expectedTopic,
    this.mood,
    this.checkoutTime,
    this.checkoutLatitude,
    this.checkoutLongitude,
    this.checkoutQrValue,
    this.learnedToday,
    this.feedback,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'student_id': studentId,
      'checkin_time': checkinTime,
      'checkin_latitude': checkinLatitude,
      'checkin_longitude': checkinLongitude,
      'checkin_qr_value': checkinQrValue,
      'previous_topic': previousTopic,
      'expected_topic': expectedTopic,
      'mood': mood,
      'checkout_time': checkoutTime,
      'checkout_latitude': checkoutLatitude,
      'checkout_longitude': checkoutLongitude,
      'checkout_qr_value': checkoutQrValue,
      'learned_today': learnedToday,
      'feedback': feedback,
      'is_completed': isCompleted ? 1 : 0,
    };
  }

  factory CheckinRecord.fromMap(Map<String, dynamic> map) {
    return CheckinRecord(
      id: map['id'],
      studentId: map['student_id'],
      checkinTime: map['checkin_time'],
      checkinLatitude: map['checkin_latitude'],
      checkinLongitude: map['checkin_longitude'],
      checkinQrValue: map['checkin_qr_value'],
      previousTopic: map['previous_topic'],
      expectedTopic: map['expected_topic'],
      mood: map['mood'],
      checkoutTime: map['checkout_time'],
      checkoutLatitude: map['checkout_latitude'],
      checkoutLongitude: map['checkout_longitude'],
      checkoutQrValue: map['checkout_qr_value'],
      learnedToday: map['learned_today'],
      feedback: map['feedback'],
      isCompleted: (map['is_completed'] ?? 0) == 1,
    );
  }
}

class CheckoutData {
  final String checkoutTime;
  final double checkoutLatitude;
  final double checkoutLongitude;
  final String? checkoutQrValue;
  final String learnedToday;
  final String feedback;

  CheckoutData({
    required this.checkoutTime,
    required this.checkoutLatitude,
    required this.checkoutLongitude,
    this.checkoutQrValue,
    required this.learnedToday,
    required this.feedback,
  });

  Map<String, dynamic> toMap() {
    return {
      'checkout_time': checkoutTime,
      'checkout_latitude': checkoutLatitude,
      'checkout_longitude': checkoutLongitude,
      'checkout_qr_value': checkoutQrValue,
      'learned_today': learnedToday,
      'feedback': feedback,
      'is_completed': 1,
    };
  }
}
