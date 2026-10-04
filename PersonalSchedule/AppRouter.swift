import Observation

/// One section of the Collection Grid: the three the Progress tab shows.
enum CollectionSection: Hashable, CaseIterable {
    case four, five, topic
}

/// Which tab is showing, and which Collection Grid section another screen wants the Progress tab to
/// open at. The 词 cards and the Today sliver both end at Progress; this is how they say where.
@MainActor
@Observable
final class AppRouter {
    var tab: AppTab = .today
    var focusedSection: CollectionSection?

    func showProgress(at section: CollectionSection) {
        focusedSection = section
        tab = .progress
    }
}
