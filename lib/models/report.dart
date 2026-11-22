enum ReportReason {
  damagedItem,
  missedMeetup,
  paymentScam,
  counterfeitOrIllegal,
  harassment,
  suspiciousAccount,
  other,
}

extension ReportReasonExtension on ReportReason {
  String get label {
    switch (this) {
      case ReportReason.damagedItem:
        return 'สินค้าไม่ตรงกับที่ระบุ / ชำรุดเสียหาย';
      case ReportReason.missedMeetup:
        return 'ไม่มาตามนัดหมาย';
      case ReportReason.paymentScam:
        return 'ชักชวนให้โอนเงินก่อนรับสินค้า';
      case ReportReason.counterfeitOrIllegal:
        return 'สินค้าลอกเลียนแบบ / ของปลอม / ผิดกฎหมาย';
      case ReportReason.harassment:
        return 'ใช้คำหยาบคาย / คุกคามผ่านช่องแชท';
      case ReportReason.suspiciousAccount:
        return 'บัญชีผู้ใช้น่าสงสัย / สวมรอย';
      case ReportReason.other:
        return 'อื่น ๆ';
    }
  }
}

enum ReportStatus { open, dismissed, actioned }

extension ReportStatusExtension on ReportStatus {
  String get label {
    switch (this) {
      case ReportStatus.open:
        return 'รอดำเนินการ';
      case ReportStatus.dismissed:
        return 'ปิดเรื่องแล้ว';
      case ReportStatus.actioned:
        return 'ดำเนินการแล้ว';
    }
  }
}

enum AdminReportAction { dismiss, suspendUser, cancelOrder, suspendAndCancel }

class ReportModel {
  final String id;
  final String reporterId;
  final String reportedUserId;
  final String? orderId;
  final String? productId;
  final ReportReason reason;
  final String detail;
  final ReportStatus status;
  final DateTime createdAt;
  final String? adminId;
  final String? adminNote;
  final DateTime? resolvedAt;

  const ReportModel({
    required this.id,
    required this.reporterId,
    required this.reportedUserId,
    required this.reason,
    required this.detail,
    required this.createdAt,
    this.orderId,
    this.productId,
    this.status = ReportStatus.open,
    this.adminId,
    this.adminNote,
    this.resolvedAt,
  });

  ReportModel copyWith({
    String? id,
    String? reporterId,
    String? reportedUserId,
    String? orderId,
    String? productId,
    ReportReason? reason,
    String? detail,
    ReportStatus? status,
    DateTime? createdAt,
    String? adminId,
    String? adminNote,
    DateTime? resolvedAt,
  }) {
    return ReportModel(
      id: id ?? this.id,
      reporterId: reporterId ?? this.reporterId,
      reportedUserId: reportedUserId ?? this.reportedUserId,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      reason: reason ?? this.reason,
      detail: detail ?? this.detail,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      adminId: adminId ?? this.adminId,
      adminNote: adminNote ?? this.adminNote,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}
