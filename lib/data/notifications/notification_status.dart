enum PrayerNotificationPermission { unknown, granted, denied }

enum PrayerNotificationSyncState { idle, syncing, ready, failed }

class PrayerNotificationStatus {
  const PrayerNotificationStatus({
    this.permission = PrayerNotificationPermission.unknown,
    this.exactAlarmAvailable = true,
    this.syncState = PrayerNotificationSyncState.idle,
    this.scheduledCount = 0,
    this.scheduledThrough,
    this.nextNotification,
    this.lastError,
    this.lastRefresh,
  });

  final PrayerNotificationPermission permission;
  final bool exactAlarmAvailable;
  final PrayerNotificationSyncState syncState;
  final int scheduledCount;
  final DateTime? scheduledThrough;
  final DateTime? nextNotification;
  final String? lastError;
  final DateTime? lastRefresh;

  PrayerNotificationStatus copyWith({
    PrayerNotificationPermission? permission,
    bool? exactAlarmAvailable,
    PrayerNotificationSyncState? syncState,
    int? scheduledCount,
    DateTime? scheduledThrough,
    bool clearScheduledThrough = false,
    DateTime? nextNotification,
    bool clearNextNotification = false,
    String? lastError,
    DateTime? lastRefresh,
    bool clearError = false,
  }) {
    return PrayerNotificationStatus(
      permission: permission ?? this.permission,
      exactAlarmAvailable: exactAlarmAvailable ?? this.exactAlarmAvailable,
      syncState: syncState ?? this.syncState,
      scheduledCount: scheduledCount ?? this.scheduledCount,
      scheduledThrough: clearScheduledThrough
          ? null
          : scheduledThrough ?? this.scheduledThrough,
      nextNotification: clearNextNotification
          ? null
          : nextNotification ?? this.nextNotification,
      lastError: clearError ? null : lastError ?? this.lastError,
      lastRefresh: lastRefresh ?? this.lastRefresh,
    );
  }
}
