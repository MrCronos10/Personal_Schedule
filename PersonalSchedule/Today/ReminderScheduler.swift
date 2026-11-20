import Foundation
import SwiftData
import UserNotifications

/// Puts `ReminderPlan`'s answer into iOS as local notifications. It holds no rule: every refresh
/// replaces the app's pending **Reminders** with what the plan says now, so ticking, unticking,
/// editing, pausing or turning a switch off are all just "refresh".
///
/// Reminders are scheduled one per day rather than as a repeating trigger, so a day already ticked can
/// be left out. They only exist while the app is opened at least once a week (spec decision 5).
@MainActor
final class ReminderScheduler: NSObject, UNUserNotificationCenterDelegate {
    static let shared = ReminderScheduler()

    /// Every reminder's identifier starts with this, so a refresh clears only its own and never
    /// another kind of notification the app may send one day.
    private static let prefix = "reminder-"

    /// What tapping a reminder does. The app sets this to show 今天. A tap that arrives before it is
    /// set (one that launched the app) is kept and run as soon as it is.
    var onOpen: (() -> Void)? {
        didSet {
            guard pendingOpen, let onOpen else { return }
            pendingOpen = false
            onOpen()
        }
    }
    private var pendingOpen = false

    private let center = UNUserNotificationCenter.current()
    /// The refresh in flight, and whether another was asked for meanwhile. A burst of saves runs at
    /// most one more refresh after the current one, reading the newest state, rather than one each.
    private var running: Task<Void, Never>?
    private var wantsAnother = false
    private var latestContext: ModelContext?

    /// Replaces every pending reminder with what `ReminderPlan` says now.
    func refresh(_ context: ModelContext) {
        latestContext = context
        guard running == nil else {
            wantsAnother = true
            return
        }
        running = Task {
            repeat {
                wantsAnother = false
                if let context = latestContext {
                    await replacePending(context, now: Date())
                }
            } while wantsAnother
            running = nil
        }
    }

    /// What iOS says about reminders right now.
    func permission() async -> ReminderPermission {
        ReminderPermission(await center.notificationSettings().authorizationStatus)
    }

    /// Asks iOS for permission if it has never been asked, and says where that leaves things. Called
    /// the first time a switch is turned on, never at launch (spec decision 6).
    func requestPermissionIfNeeded() async -> ReminderPermission {
        let current = await permission()
        guard current == .notAsked else { return current }
        _ = try? await center.requestAuthorization(options: [.alert, .sound])
        return await permission()
    }

    private func replacePending(_ context: ModelContext, now: Date) async {
        let ours = await center.pendingNotificationRequests()
            .map(\.identifier)
            .filter { $0.hasPrefix(Self.prefix) }
        center.removePendingNotificationRequests(withIdentifiers: ours)

        // Refused: the switches are kept as they were, and their reminders come back once allowed.
        guard await permission() == .allowed else { return }

        // One calendar, read once, for both the day and the minute (Day.swift's own rule), Gregorian
        // whatever the phone's calendar is (ADR 0003).
        let calendar = Day.calendar
        let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: now)
        let today = Day(year: parts.year ?? 0, month: parts.month ?? 0, day: parts.day ?? 0)
        let nowMinutes = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
        let actions = (try? context.fetch(DayPlan.descriptor)) ?? []
        let reminders = ReminderPlan.reminders(actions, today: today, nowMinutes: nowMinutes)

        for (index, reminder) in reminders.enumerated() {
            var moment = DateComponents()
            // Gregorian, but no time zone pinned: the reminder fires at that clock time wherever the
            // phone is, as the day rule does after travel.
            moment.calendar = Calendar(identifier: .gregorian)
            moment.year = reminder.day.year
            moment.month = reminder.day.month
            moment.day = reminder.day.dayOfMonth
            moment.hour = reminder.time.hour
            moment.minute = reminder.time.minute

            let content = UNMutableNotificationContent()
            // The student's own title, never translated, and nothing of the app's added to it.
            content.title = reminder.action.title
            content.subtitle = Self.clockText(for: reminder.time, in: calendar)
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: "\(Self.prefix)\(reminder.day.number)-\(index)",
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: moment, repeats: false)
            )
            try? await center.add(request)
        }
    }

    /// The time in the phone's own clock style (21:00, or 9:00 PM).
    private static func clockText(for time: TimeOfDay, in calendar: Calendar) -> String {
        let moment = calendar.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: Date())
        return moment?.formatted(date: .omitted, time: .shortened) ?? ""
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// A reminder arriving while the app is open still shows: it is the one the student asked for.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    /// Tapping a reminder opens 今天.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        await MainActor.run {
            if let onOpen = self.onOpen {
                onOpen()
            } else {
                self.pendingOpen = true
            }
        }
    }
}
