part of 'app_state.dart';

/// Admin queries, blocking, suspension, reports, and disputes.
extension AppStateTrustSafety on AppState {
  AdminQueryResult<List<UserModel>> adminUsers({String query = ''}) {
    if (!isAdmin) {
      return const AdminQueryResult.failure('เฉพาะผู้ดูแลระบบเท่านั้น');
    }
    final normalized = query.trim().toLowerCase();
    final result = users.where((user) {
      return normalized.isEmpty ||
          user.name.toLowerCase().contains(normalized) ||
          user.phone.contains(normalized);
    }).toList()..sort((a, b) => a.name.compareTo(b.name));
    return AdminQueryResult.success(List.unmodifiable(result));
  }

  AdminQueryResult<List<ReportModel>> adminReports() {
    if (!isAdmin) {
      return const AdminQueryResult.failure('เฉพาะผู้ดูแลระบบเท่านั้น');
    }
    final result = List<ReportModel>.of(reports)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return AdminQueryResult.success(List.unmodifiable(result));
  }

  String _blockedPairKey(String firstUserId, String secondUserId) {
    final ids = [firstUserId, secondUserId]..sort();
    return '${ids[0]}|${ids[1]}';
  }

  bool areUsersBlocked(String firstUserId, String secondUserId) =>
      _blockedUserPairs.contains(_blockedPairKey(firstUserId, secondUserId));

  bool isBlocked(String userId) =>
      isLoggedIn && areUsersBlocked(currentUser.id, userId);

  Set<String> _blockedUserIdsFor(String userId) {
    final blocked = <String>{};
    for (final pair in _blockedUserPairs) {
      final ids = pair.split('|');
      if (ids.length != 2) continue;
      if (ids[0] == userId) blocked.add(ids[1]);
      if (ids[1] == userId) blocked.add(ids[0]);
    }
    return blocked;
  }

  String? blockUser(String userId) {
    final sessionError = _expireSuspendedSession();
    if (sessionError != null) return sessionError;
    if (!isLoggedIn) return 'เข้าสู่ระบบก่อนบล็อกผู้ใช้';
    if (userId == currentUser.id) return 'ไม่สามารถบล็อกตัวเองได้';
    if (userById(userId) == null) return 'ไม่พบผู้ใช้นี้';
    _blockedUserPairs.add(_blockedPairKey(currentUser.id, userId));
    notifyListeners();
    return null;
  }

  String? unblockUser(String userId) {
    final sessionError = _expireSuspendedSession();
    if (sessionError != null) return sessionError;
    if (!isLoggedIn) return 'เข้าสู่ระบบก่อนปลดบล็อกผู้ใช้';
    _blockedUserPairs.remove(_blockedPairKey(currentUser.id, userId));
    notifyListeners();
    return null;
  }

  List<UserModel> blockedUsersForCurrentUser() {
    if (!isLoggedIn) return const [];
    final ids = _blockedUserIdsFor(currentUser.id);
    return users.where((user) => ids.contains(user.id)).toList();
  }

  String? suspendUser(String userId, String reason) {
    if (!isAdmin) return 'เฉพาะผู้ดูแลระบบเท่านั้น';
    if (userId == currentUser.id) return 'ไม่สามารถระงับบัญชีตัวเองได้';
    final index = users.indexWhere((user) => user.id == userId);
    if (index == -1) return 'ไม่พบผู้ใช้นี้';
    if (users[index].role == UserRole.admin) {
      return 'ไม่สามารถระงับบัญชีผู้ดูแลระบบได้';
    }
    final detail = reason.trim();
    if (detail.isEmpty) return 'กรุณาระบุเหตุผลในการระงับบัญชี';
    users[index] = users[index].copyWith(
      isSuspended: true,
      suspensionReason: detail,
    );
    _suspendedUserReasons[userId] = detail;
    notifyListeners();
    return null;
  }

  String? unsuspendUser(String userId) {
    if (!isAdmin) return 'เฉพาะผู้ดูแลระบบเท่านั้น';
    final index = users.indexWhere((user) => user.id == userId);
    if (index == -1) return 'ไม่พบผู้ใช้นี้';
    users[index] = users[index].copyWith(
      isSuspended: false,
      clearSuspensionReason: true,
    );
    _suspendedUserReasons.remove(userId);
    notifyListeners();
    return null;
  }

  String? disputeOrder(String orderId, String reason, String details) {
    final sessionError = _expireSuspendedSession();
    if (sessionError != null) return sessionError;
    final index = orders.indexWhere((order) => order.id == orderId);
    if (index == -1) return 'ไม่พบคำสั่งซื้อนี้';
    final order = orders[index];
    if (!isLoggedIn ||
        (currentUser.id != order.buyerId && currentUser.id != order.sellerId)) {
      return 'เฉพาะผู้ซื้อหรือผู้ขายของคำสั่งซื้อนี้เท่านั้นที่รายงานได้';
    }
    final now = _clock();
    if (order.status == OrderStatus.completed) {
      final completedAt = order.completedAt;
      if (completedAt == null ||
          now.difference(completedAt) >
              const Duration(days: kDisputeWindowDays)) {
        return 'แจ้งปัญหาได้ภายใน $kDisputeWindowDays วันหลังคำสั่งซื้อสำเร็จ';
      }
    } else if (order.status != OrderStatus.pending) {
      return 'แจ้งปัญหาได้เฉพาะคำสั่งซื้อที่รอนัดรับ หรือสำเร็จภายใน $kDisputeWindowDays วัน';
    }
    final trimmedDetail = details.trim();
    if (trimmedDetail.isEmpty) return 'กรุณาระบุรายละเอียดของปัญหา';
    if (trimmedDetail.length > kReportDetailMaxLength) {
      return 'รายละเอียดต้องไม่เกิน $kReportDetailMaxLength ตัวอักษร';
    }
    final targetId = currentUser.id == order.buyerId
        ? order.sellerId
        : order.buyerId;
    orders[index] = order.copyWith(
      status: OrderStatus.disputed,
      previousStatus: order.status,
      events: [
        ...order.events,
        OrderEvent(
          at: now,
          actorId: currentUser.id,
          status: OrderStatus.disputed,
        ),
      ],
    );
    reports.insert(
      0,
      ReportModel(
        id: 'DISP-${now.microsecondsSinceEpoch}',
        orderId: orderId,
        reporterId: currentUser.id,
        reportedUserId: targetId,
        reason: _reportReasonFromLabel(reason),
        detail: trimmedDetail,
        createdAt: now,
      ),
    );
    _notifyOrderParticipants(
      order,
      body: 'คำสั่งซื้อ $orderId ถูกส่งให้ทีมดูแลตรวจสอบ',
    );
    notifyListeners();
    return null;
  }

  ReportReason _reportReasonFromLabel(String label) =>
      ReportReason.values
          .where((reason) => reason.label == label)
          .firstOrNull ??
      ReportReason.other;

  String? submitReport({
    required String reportedUserId,
    required ReportReason reason,
    required String detail,
    String? orderId,
    String? productId,
  }) {
    if (productId != null && productId.isEmpty) productId = null;
    final sessionError = _expireSuspendedSession();
    if (sessionError != null) return sessionError;
    if (!isLoggedIn) return 'เข้าสู่ระบบก่อนส่งรายงาน';
    if (reportedUserId == currentUser.id) return 'ไม่สามารถรายงานตัวเองได้';
    if (userById(reportedUserId) == null) return 'ไม่พบผู้ใช้ที่ต้องการรายงาน';
    if (orderId != null) {
      final order = orders.where((item) => item.id == orderId).firstOrNull;
      if (order == null) return 'ไม่พบคำสั่งซื้อที่ระบุ';
      final isBuyer = currentUser.id == order.buyerId;
      final isSeller = currentUser.id == order.sellerId;
      final otherId = isBuyer
          ? order.sellerId
          : isSeller
          ? order.buyerId
          : null;
      if (otherId == null || reportedUserId != otherId) {
        return 'รายงานได้เฉพาะคู่กรณีของคำสั่งซื้อนี้';
      }
    }
    if (productId != null) {
      final product = products
          .where((item) => item.id == productId)
          .firstOrNull;
      if (product == null || product.sellerId != reportedUserId) {
        return 'สินค้าไม่ตรงกับผู้ใช้ที่ถูกรายงาน';
      }
    }
    final trimmedDetail = detail.trim();
    if (trimmedDetail.isEmpty) return 'กรุณาระบุรายละเอียดของปัญหา';
    if (trimmedDetail.length > kReportDetailMaxLength) {
      return 'รายละเอียดต้องไม่เกิน $kReportDetailMaxLength ตัวอักษร';
    }
    if (orderId != null &&
        reports.any(
          (report) =>
              report.reporterId == currentUser.id &&
              report.reportedUserId == reportedUserId &&
              report.orderId == orderId &&
              report.status == ReportStatus.open,
        )) {
      return 'คุณส่งรายงานเรื่องนี้สำหรับออเดอร์นี้แล้ว';
    }
    final now = DateTime.now();
    reports.insert(
      0,
      ReportModel(
        id: 'REP-${now.microsecondsSinceEpoch}',
        reporterId: currentUser.id,
        reportedUserId: reportedUserId,
        orderId: orderId,
        productId: productId,
        reason: reason,
        detail: trimmedDetail,
        createdAt: now,
      ),
    );
    notifyListeners();
    return null;
  }

  String? resolveReport(
    String reportId, {
    required AdminReportAction action,
    required String adminNote,
  }) {
    if (!isAdmin) return 'เฉพาะผู้ดูแลระบบเท่านั้น';
    final reportIndex = reports.indexWhere((report) => report.id == reportId);
    if (reportIndex == -1) return 'ไม่พบรายงานนี้';
    final report = reports[reportIndex];
    if (report.status != ReportStatus.open) return 'รายงานนี้ปิดไปแล้ว';
    final note = adminNote.trim();
    if (action != AdminReportAction.dismiss && note.isEmpty) {
      return 'กรุณาบันทึกหมายเหตุแอดมินเมื่อดำเนินการ';
    }

    final shouldSuspend =
        action == AdminReportAction.suspendUser ||
        action == AdminReportAction.suspendAndCancel;
    final shouldCancel =
        action == AdminReportAction.cancelOrder ||
        action == AdminReportAction.suspendAndCancel;
    final target = userById(report.reportedUserId);
    if (shouldSuspend) {
      if (target == null) return 'ไม่พบผู้ใช้ที่ถูกรายงาน';
      if (target.id == currentUser.id || target.role == UserRole.admin) {
        return 'ไม่สามารถระงับบัญชีแอดมินหรือตัวเองได้';
      }
    }
    final orderIndex = report.orderId == null
        ? -1
        : orders.indexWhere((order) => order.id == report.orderId);
    if (shouldCancel) {
      if (orderIndex == -1) return 'รายงานนี้ไม่มีออเดอร์ที่ยกเลิกได้';
      final order = orders[orderIndex];
      if (order.status != OrderStatus.pending &&
          order.status != OrderStatus.disputed) {
        return 'ยกเลิกได้เฉพาะออเดอร์ที่รอนัดรับหรือรอตรวจสอบ';
      }
    }

    final now = DateTime.now();
    if (shouldSuspend) {
      final userIndex = users.indexWhere(
        (user) => user.id == report.reportedUserId,
      );
      users[userIndex] = users[userIndex].copyWith(
        isSuspended: true,
        suspensionReason: note,
      );
      _suspendedUserReasons[report.reportedUserId] = note;
    }

    if (orderIndex != -1) {
      final order = orders[orderIndex];
      if (order.status == OrderStatus.disputed) {
        final nextStatus = shouldCancel
            ? OrderStatus.cancelled
            : order.previousStatus ?? OrderStatus.pending;
        orders[orderIndex] = order.copyWith(
          status: nextStatus,
          cancelledBy: shouldCancel ? currentUser.id : order.cancelledBy,
          cancelReason: shouldCancel
              ? 'ยกเลิกโดยผู้ดูแลหลังตรวจสอบรายงาน'
              : null,
          cancelledAt: shouldCancel ? now : order.cancelledAt,
          clearPreviousStatus: true,
          events: [
            ...order.events,
            OrderEvent(at: now, actorId: currentUser.id, status: nextStatus),
          ],
        );
        if (shouldCancel) _restoreReservedProducts(order);
      } else if (shouldCancel) {
        orders[orderIndex] = order.copyWith(
          status: OrderStatus.cancelled,
          cancelledBy: currentUser.id,
          cancelReason: 'ยกเลิกโดยผู้ดูแลหลังตรวจสอบรายงาน',
          cancelledAt: now,
          events: [
            ...order.events,
            OrderEvent(
              at: now,
              actorId: currentUser.id,
              status: OrderStatus.cancelled,
            ),
          ],
        );
        _restoreReservedProducts(order);
      }
      if (orderIndex != -1) {
        _notifyOrderParticipants(
          orders[orderIndex],
          body: 'มีการอัปเดตคำสั่งซื้อ ${orders[orderIndex].id}',
        );
      }
    }

    reports[reportIndex] = report.copyWith(
      status: action == AdminReportAction.dismiss
          ? ReportStatus.dismissed
          : ReportStatus.actioned,
      adminId: currentUser.id,
      adminNote: note.isEmpty ? null : note,
      resolvedAt: now,
    );
    for (final userId in {report.reporterId, report.reportedUserId}) {
      _notifyUser(
        userId: userId,
        type: AppNotificationType.reportUpdated,
        title: 'อัปเดตผลการตรวจสอบรายงาน',
        body: action == AdminReportAction.dismiss
            ? 'รายงาน ${report.id} ถูกปิดเรื่องแล้ว'
            : 'มีการดำเนินการกับรายงาน ${report.id}',
        refType: 'report',
        refId: report.id,
      );
    }
    notifyListeners();
    return null;
  }

  String? resolveDispute(String reportId, ReportResolution resolution) {
    if (!isAdmin) return 'เฉพาะผู้ดูแลระบบเท่านั้น';
    final report = reports.where((item) => item.id == reportId).firstOrNull;
    if (report == null) return 'ไม่พบรายงานนี้';
    final action = switch (resolution) {
      ReportResolution.close => AdminReportAction.dismiss,
      ReportResolution.cancelOrder => AdminReportAction.cancelOrder,
      ReportResolution.accountSuspended => AdminReportAction.suspendUser,
    };
    return resolveReport(
      reportId,
      action: action,
      adminNote: resolution == ReportResolution.close
          ? ''
          : 'ดำเนินการโดยผู้ดูแลระบบ',
    );
  }
}
