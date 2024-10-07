import Foundation

class Logger {
    private var session: Session
    private var scope: String

    init(session: Session, scope: String) {
        self.session = session
        self.scope = scope
    }

    func critical(message: String) {
        session.pushLog(message: "CRITICAL: \(message)")
    }

    func error(message: String) {
        session.pushLog(message: "ERROR: \(message)")
    }

    func warn(message: String) {
        session.pushLog(message: "[\(scope)] WARN: \(message)")
    }

    func info(message: String) {
        session.pushLog(message: "INFO: \(message)")
    }

    func scope(name: String) -> Logger {
        return Logger(session: session, scope: "\(scope).\(name)")
    }
}
