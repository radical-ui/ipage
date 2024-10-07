//import Foundation
//import Combine
//
//class Bridge {
//    private var logger: Logger
//    private var session: Session
//    private var cancellables = Set<AnyCancellable>()
//
//    var onError: Listener<String>
//    var onHasInternet: Listener<Bool>
//    var onObjectSet: Listener<(String, Object)>
//    var onObjectRemoved: Listener<String>
//
//    private var isOffline = false
//    private var url: String?
//    private var websocket: URLSessionWebSocketTask?
//    private var isRunning = false
//
//    private let jsonEncoder = JSONEncoder()
//    private let jsonDecoder = JSONDecoder()
//    private let urlSession = URLSession(configuration: .default)
//
//    init(logger: Logger, session: Session) {
//        self.logger = logger
//        self.session = session
//        self.onError = Listener(logger: logger)
//        self.onHasInternet = Listener(logger: logger)
//        self.onObjectSet = Listener(logger: logger)
//        self.onObjectRemoved = Listener(logger: logger)
//
//        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
//    }
//
//    func start(url: String) {
//        guard !isRunning else {
//            logger.info("start called again, but skipping because bridge is already running")
//            return
//        }
//        
//        logger.info("starting")
//
//        self.url = "\(url)?session_id=\(session.getId())"
//        connect()
//    }
//
//    func watch(objectId: String, onComplete: @escaping () -> Void) {
//        sendMessage(
//            OutgoingMessage.watch(requestId: listenForAcknowledgement(onComplete), id: objectId)
//        )
//    }
//
//    func unwatch(objectId: String, onComplete: @escaping () -> Void) {
//        sendMessage(
//            OutgoingMessage.unwatch(requestId: listenForAcknowledgement(onComplete), id: objectId)
//        )
//    }
//
//    func emitBindingUpdate(key: String, data: JsonElement, onComplete: @escaping () -> Void) {
//        sendMessage(
//            OutgoingMessage.emitBindingUpdate(requestId: listenForAcknowledgement(onComplete), key: key, data: data)
//        )
//    }
//
//    private func listenForAcknowledgement(_ callback: @escaping () -> Void) -> String {
//        return UUID().uuidString
//    }
//
//    private func callError(message: String) {
//        onError.emit(message)
//    }
//
//    private func sendMessage(_ message: OutgoingMessage) {
//        guard let websocket = websocket else {
//            logger.error("must call start() before watch() or fireEvent()")
//            return
//        }
//        
//        do {
//            let jsonMessage = try jsonEncoder.encode(message)
//            let jsonString = String(data: jsonMessage, encoding: .utf8) ?? "{}"
//            websocket.send(.string(jsonString)) { error in
//                if let error = error {
//                    self.logger.error("Error sending message: \(error)")
//                }
//            }
//        } catch {
//            logger.error("Failed to encode message: \(error)")
//        }
//    }
//
//    private func parseIncomingJson(_ data: String) -> [IncomingMessage] {
//        do {
//            let messages = try jsonDecoder.decode([IncomingMessage].self, from: Data(data.utf8))
//            return messages
//        } catch {
//            callError("Failed to parse information from server.")
//            logger.critical("failed to parse json of incoming message: \(error). JSON: \(data)")
//            return []
//        }
//    }
//
//    private func queueRetry() {
//        logger.info("retrying websocket connection")
//        DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
//            self.connect()
//        }
//    }
//
//    private func connect() {
//        logger.info("connecting")
//
//        guard let url = url else {
//            logger.error("must call .start() before .connect()")
//            return
//        }
//
//        websocket = urlSession.webSocketTask(with: URL(string: url)!)
//        websocket?.resume()
//
//        listenForMessages()
//    }
//
//    private func listenForMessages() {
//        websocket?.receive { result in
//            switch result {
//            case .success(let message):
//                switch message {
//                case .string(let text):
//                    self.parseIncomingJson(text).forEach { self.handleIncomingMessage($0) }
//                default:
//                    break
//                }
//                self.listenForMessages() // Listen for the next message
//            case .failure(let error):
//                self.handleWebSocketError(error)
//            }
//        }
//    }
//
//    private func handleWebSocketError(_ error: Error) {
//        logger.warn("WebSocket error: \(error)")
//        isOffline = true
//        onHasInternet.emit(false)
//        queueRetry()
//    }
//
//    private func handleIncomingMessage(_ message: IncomingMessage) {
//        switch message {
//        case let .removeObject(id):
//            onObjectRemoved.emit(id)
//        case let .setObject(id, data):
//            onObjectSet.emit((id, data))
//        case let .acknowledge(requestId, error, retryAfterSeconds):
//            logger.warn("TODO acknowledge: \(requestId ?? "")")
//        }
//    }
//}
//
//// OutgoingMessage and IncomingMessage definitions
//
//enum OutgoingMessage: Codable {
//    case watch(requestId: String, id: String)
//    case unwatch(requestId: String, id: String)
//    case emitBindingUpdate(requestId: String, key: String, data: JsonElement)
//
//    enum CodingKeys: String, CodingKey {
//        case requestId = "request_id"
//        case id
//        case key
//        case data
//    }
//
//    enum MessageType: String, Codable {
//        case watch = "watch"
//        case unwatch = "unwatch"
//        case emitBindingUpdate = "emit_binding_update"
//    }
//
//    enum CodingError: Error {
//        case unknownMessageType
//    }
//
//    init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        let type = try container.decode(MessageType.self, forKey: .requestId)
//
//        switch type {
//        case .watch:
//            let id = try container.decode(String.self, forKey: .id)
//            let requestId = try container.decode(String.self, forKey: .requestId)
//            self = .watch(requestId: requestId, id: id)
//
//        case .unwatch:
//            let id = try container.decode(String.self, forKey: .id)
//            let requestId = try container.decode(String.self, forKey: .requestId)
//            self = .unwatch(requestId: requestId, id: id)
//
//        case .emitBindingUpdate:
//            let key = try container.decode(String.self, forKey: .key)
//            let data = try container.decode(JsonElement.self, forKey: .data)
//            let requestId = try container.decode(String.self, forKey: .requestId)
//            self = .emitBindingUpdate(requestId: requestId, key: key, data: data)
//        }
//    }
//}
//
//enum IncomingMessage: Codable {
//    case removeObject(id: String)
//    case setObject(id: String, data: JsonElement)
//    case acknowledge(requestId: String?, error: String?, retryAfterSeconds: Int?)
//
//    enum CodingKeys: String, CodingKey {
//        case id
//        case data
//        case requestId = "request_id"
//        case error
//        case retryAfterSeconds = "retry_after_seconds"
//    }
//
//    enum MessageType: String, Codable {
//        case removeObject = "remove_object"
//        case setObject = "set_object"
//        case acknowledge = "acknowledge"
//    }
//
//    init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        let type = try container.decode(MessageType.self, forKey: .requestId)
//
//        switch type {
//        case .removeObject:
//            let id = try container.decode(String.self, forKey: .id)
//            self = .removeObject(id: id)
//
//        case .setObject:
//            let id = try container.decode(String.self, forKey: .id)
//            let data = try container.decode(JsonElement.self, forKey: .data)
//            self = .setObject(id: id, data: data)
//
//        case .acknowledge:
//            let requestId = try container.decodeIfPresent(String.self, forKey: .requestId)
//            let error = try container.decodeIfPresent(String.self, forKey: .error)
//            let retryAfterSeconds = try container.decodeIfPresent(Int.self, forKey: .retryAfterSeconds)
//            self = .acknowledge(requestId: requestId, error: error, retryAfterSeconds: retryAfterSeconds)
//        }
//    }
//}
