import Foundation

protocol ProgressStore {
    func load() -> ProgressState
    func save(_ progress: ProgressState)
}

final class UserDefaultsProgressStore: ProgressStore {
    private enum Constants {
        static let key = "mathDaily.progressState"
    }

    private let defaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
    }

    func load() -> ProgressState {
        guard let data = defaults.data(forKey: Constants.key),
              let decoded = try? decoder.decode(ProgressState.self, from: data) else {
            return ProgressState(startedAt: Calendar.current.startOfDay(for: Date()))
        }

        return decoded
    }

    func save(_ progress: ProgressState) {
        guard let data = try? encoder.encode(progress) else {
            return
        }

        defaults.set(data, forKey: Constants.key)
    }
}
