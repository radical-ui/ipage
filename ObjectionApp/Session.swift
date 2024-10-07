import Foundation

class Session {
    private var sessionId: UUID = UUID()

    func pushLog(message: String) {
        print("[\(sessionId)] \(message)")
    }

    func getId() -> String {
        return sessionId.uuidString
    }
}
