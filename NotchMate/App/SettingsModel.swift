import Foundation
import NotchMateKit

/// Observable wrapper around `NotchSettings` that persists every change.
@MainActor
final class SettingsModel: ObservableObject {
    @Published var settings: NotchSettings {
        didSet {
            guard settings != oldValue else { return }
            store.save(settings)
            onChange?(settings)
        }
    }

    /// Called after every change; the notch controller uses it to re-layout.
    var onChange: (@MainActor (NotchSettings) -> Void)?

    private let store: SettingsStore

    init(store: KeyValueStore) {
        self.store = SettingsStore(store: store)
        self.settings = self.store.load()
    }

    func resetToDefaults() {
        store.reset()
        settings = store.load()
    }
}
