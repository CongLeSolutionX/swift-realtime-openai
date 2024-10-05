import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking  // For compatibility with older macOS versions.
#endif

/// Manages a real-time connection to the OpenAI API, handling WebSocket communication and events.
/// Conforms to `NSObject` for URLSessionDelegate conformance and `Sendable` for safe usage in concurrent contexts.
public final class RealtimeAPI: NSObject, Sendable {
    /// Called when the WebSocket connection is closed or lost.  Execute on the main thread.
    @MainActor public var onDisconnect: (@Sendable () -> Void)?
    /// An asynchronous stream that emits server events received through the WebSocket.
    public let events: AsyncThrowingStream<ServerEvent, Error>

    /// JSON encoder for encoding client events.  Configured for snake_case.
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()
    /// JSON decoder for decoding server events. Configured for snake_case.
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    /// The underlying `URLSessionWebSocketTask` managing the connection.
    private let task: URLSessionWebSocketTask
    /// Continuation for the `events` stream.
    private let stream: AsyncThrowingStream<ServerEvent, Error>.Continuation

    /// Initializes a new `RealtimeAPI` instance with a URL request.
    /// - Parameter request: The URL request for the WebSocket connection. Should include necessary headers (e.g., Authorization).
    public init(connectingTo request: URLRequest) {
        (events, stream) = AsyncThrowingStream.makeStream(of: ServerEvent.self)
        task = URLSession.shared.webSocketTask(with: request)
        super.init()
        task.delegate = self  // Set the delegate for WebSocket events.
        receiveMessage()       // Start receiving messages.
        task.resume()         // Start the WebSocket task.
    }


    /// Initializes the RealtimeAPI with auth token and model
    /// - Parameters:
    ///   - authToken: The OpenAI API authentication token.
    ///   - model: The name of the model to use.  Defaults to "gpt-4o-realtime-preview-2024-10-01".
    public convenience init(authToken: String, model: String = "gpt-4o-realtime-preview-2024-10-01") {
        var request = URLRequest(url: URL(string: "wss://api.openai.com/v1/realtime")!.appending(queryItems: [URLQueryItem(name: "model", value: model)]))
        request.addValue("realtime=v1", forHTTPHeaderField: "OpenAI-Beta") //Sets the OpenAI beta header
        request.addValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization") //Sets bearer token authorization
        self.init(connectingTo: request)
    }

    /// Cancels the WebSocket task, finishes the event stream and calls onDisconnect when deinitialized
    deinit {
        task.cancel(with: .goingAway, reason: nil) // Close the WebSocket connection gracefully.
        stream.finish()                           // Signal the end of the event stream.
        onDisconnect?()                           // Notify any observers of disconnection.

    }

    /// Receives messages from the WebSocket, decodes them into `ServerEvent`s, and yields them to the `events` stream.
    private func receiveMessage() {
        task.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure(let error):
                self.stream.yield(error: error) // Yield any errors to the stream.
            case .success(let message):
                switch message {
                case let .string(text):
					self.stream.yield(with: Result { try self.decoder.decode(ServerEvent.self, from: text.data(using: .utf8)!) }) // Decode and yield server events.
                    
                case .data:
                    self.stream.yield(error: RealtimeAPIError.invalidMessage)  // Handle invalid message types.
                @unknown default:
                    self.stream.yield(error: RealtimeAPIError.invalidMessage)  // Handle unknown message types.
                }
            }
            self.receiveMessage()  // Continue receiving messages recursively.
        }
    }

    /// Sends a client event to the server over the WebSocket.
    /// - Parameter event: The client event to send.
    /// - Throws: An error if encoding or sending the event fails.
    public func send(event: ClientEvent) async throws {
        let message = try URLSessionWebSocketTask.Message.string(String(data: encoder.encode(event), encoding: .utf8)!)
        try await task.send(message) // Send the encoded event as a string message.
    }
}

// MARK: - URLSessionWebSocketDelegate

/// Conforms to `URLSessionWebSocketDelegate` to handle WebSocket events, specifically the closure of the connection.
extension RealtimeAPI: URLSessionWebSocketDelegate {
    /// Called when the WebSocket connection is closed.
    /// - Parameters:
    ///   - session: The URL session.
    ///   - webSocketTask: The WebSocket task that was closed.
    ///   - closeCode: The close code indicating the reason for closure.
    ///   - reason: Any data associated with the closure.
    public func urlSession(_: URLSession, webSocketTask _: URLSessionWebSocketTask, didCloseWith _: URLSessionWebSocketTask.CloseCode, reason _: Data?) {
        stream.finish()  // Signal the end of the event stream.
        Task { @MainActor in
            onDisconnect?()  // Notify any observers of disconnection on the main thread.
        }
    }
}

/// Errors specific to the `RealtimeAPI`.
enum RealtimeAPIError: Error {
    /// Indicates an invalid WebSocket message was received.
    case invalidMessage
}