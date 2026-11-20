import Testing
import UserNotifications
@testable import PersonalSchedule

/// What iOS's notification permission means for **Reminders**: one mapping, read by both the form
/// (whether to show 通知已关闭) and the scheduler (whether to schedule at all).
struct ReminderPermissionTests {
    @Test func neverAskedIsNotAsked() {
        #expect(ReminderPermission(.notDetermined) == .notAsked)
    }

    /// Refused at the prompt, or turned off later in Settings: iOS reports both as denied.
    @Test func deniedIsRefused() {
        #expect(ReminderPermission(.denied) == .refused)
    }

    /// Quiet delivery and app-clip permission still deliver, so reminders are scheduled.
    @Test(arguments: [UNAuthorizationStatus.authorized, .provisional, .ephemeral])
    func everyDeliveringStatusIsAllowed(status: UNAuthorizationStatus) {
        #expect(ReminderPermission(status) == .allowed)
    }

    // MARK: - Turning a switch on

    /// Refusing the prompt the switch just raised leaves it off.
    @Test func refusingThePromptLeavesTheSwitchOff() {
        #expect(ReminderPermission.keepsSwitchOn(before: .notAsked, after: .refused) == false)
    }

    /// Already off in Settings: the switch is kept on with 通知已关闭 under it, so its reminder comes
    /// back once Settings allows it (ticket 02: switches are kept while permission is off).
    @Test func alreadyRefusedKeepsTheSwitchOn() {
        #expect(ReminderPermission.keepsSwitchOn(before: .refused, after: .refused))
    }

    @Test func allowingKeepsTheSwitchOn() {
        #expect(ReminderPermission.keepsSwitchOn(before: .notAsked, after: .allowed))
        #expect(ReminderPermission.keepsSwitchOn(before: .allowed, after: .allowed))
    }
}
