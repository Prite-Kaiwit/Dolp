enum ReportStatus { pending, investigating, refunded, released, accountSuspended }

extension ReportStatusExtension on ReportStatus {
  String get label {
    switch (this) {
      case ReportStatus.pending:
        return 'รอดำเนินการ';
      case ReportStatus.investigating:
        return 'กำลังตรวจสอบ';
      case ReportStatus.refunded:
        return 'ตัดสิน: คืนเงินให้ผู้ซื้อ';
      case ReportStatus.released:
        return 'ตัดสิน: ปล่อยเงินให้ผู้ขาย';
      case ReportStatus.accountSuspended:
        return 'ระงับบัญชีผู้กระทำผิด';
    }
  }
}

class ReportModel {
  final String id;
  final String orderId;
  final String reporterId;
  final String reporterName;
  final String reportedUserName;
  final String reason;
  final String details;
  final String evidenceUrl;
  final double amount;
  final ReportStatus status;
  final DateTime createdAt;
  final String adminNotes;

  ReportModel({
    required this.id,
    this.orderId = '',
    required this.reporterId,
    required this.reporterName,
    required this.reportedUserName,
    required this.reason,
    required this.details,
    this.evidenceUrl = 'https://images.unsplash.com/photo-1584438784894-089d6a62b8fa?w=400',
    this.amount = 0.0,
    this.status = ReportStatus.pending,
    DateTime? createdAt,
    this.adminNotes = '',
  }) : createdAt = createdAt ?? DateTime.now();

  ReportModel copyWith({
    String? id,
    String? orderId,
    String? reporterId,
    String? reporterName,
    String? reportedUserName,
    String? reason,
    String? details,
    String? evidenceUrl,
    double? amount,
    ReportStatus? status,
    DateTime? createdAt,
    String? adminNotes,
  }) {
    return ReportModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      reporterId: reporterId ?? this.reporterId,
      reporterName: reporterName ?? this.reporterName,
      reportedUserName: reportedUserName ?? this.reportedUserName,
      reason: reason ?? this.reason,
      details: details ?? this.details,
      evidenceUrl: evidenceUrl ?? this.evidenceUrl,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      adminNotes: adminNotes ?? this.adminNotes,
    );
  }
}
