import UserNotifications

/// What iOS's notification permission means for **Reminders**. The form reads it to show 通知已关闭,
/// the scheduler to decide whether to schedule at all — one mapping, so the two can't disagree.
enum ReminderPermission: Equatable {
    /// iOS has never asked. The first switch turned on asks.
    case notAsked
    /// Reminders are delivered.
    case allowed
    /// Refused at the prompt, or turned off later in Settings. Only Settings can change it now.
    case refused

    init(_ status: UNAuthorizationStatus) {
        switch status {
        case .notDetermined: self = .notAsked
        case .denied: self = .refused
        case .authorized, .provisional, .ephemeral: self = .allowed
        @unknown default: self = .refused
        }
    }

    /// Whether a switch just turned on stays on, given the permission before and after asking. Only
    /// refusing the prompt it raised turns it back off; already off in Settings, it is kept on with
    /// 通知已关闭 under it, so its reminder comes back once Settings allows it.
    static func keepsSwitchOn(before: ReminderPermission, after: ReminderPermission) -> Bool {
        !(before == .notAsked && after == .refused)
    }
}
