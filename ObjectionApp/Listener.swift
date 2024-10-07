import Foundation

class Listener<T> {
    private var logger: Logger
    private var lastValue: T?
    private var listeners: [ListenId: (T) -> Void] = [:]
    private var onZeroed: () -> Void

    init(logger: Logger, onZeroed: @escaping () -> Void = {}) {
        self.logger = logger
        self.onZeroed = onZeroed
    }

    func getLastValue() -> T? {
        return lastValue
    }

    func listen(id: ListenId, callback: @escaping (T) -> Void) {
        listeners[id] = callback
    }

    func removeListener(id: ListenId) {
        listeners.removeValue(forKey: id)
    }

    func emit(data: T) {
        lastValue = data

        if listeners.isEmpty {
            logger.warn(message: "Emitted '\(data)' to listeners, but nobody was listening")
        }

        for (_, callback) in listeners {
            callback(data)
        }
    }
}

class ListenId: Hashable, Equatable {
    private var uuid: UUID = UUID()
    
    static func == (lhs: ListenId, rhs: ListenId) -> Bool {
        return lhs.uuid == rhs.uuid
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
}
