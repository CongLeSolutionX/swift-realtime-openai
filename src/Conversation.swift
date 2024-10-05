import Foundation

/// Errors that can occur within the `Conversation` class.
public enum ConversationError: Error {
    /// The session associated with the conversation was not found.
    case sessionNotFound
}

/// Manages a conversation with the backend, handling real-time events and updates.
/// Uses `@Observable` to automatically update SwiftUI views when changes occur.
/// Conforms to `Sendable` for safe usage in concurrent contexts.
@Observable
public final class Conversation: Sendable {
	private let client: RealtimeAPI
	@MainActor private var cancelTask: (() -> Void)?  // Task cancellation closure.
	private let errorStream: AsyncStream<ServerError>.Continuation

	/// Asynchronously streams errors encountered during the conversation.
    public let errors: AsyncStream<ServerError>
    /// The unique ID of the conversation (set after the conversation is created).
    @MainActor public private(set) var id: String?
    /// The session associated with this conversation (set after connection).
    @MainActor public private(set) var session: Session?
    /// The list of conversation entries (messages, function calls, etc.).
    @MainActor public private(set) var entries: [Item] = []
    /// Indicates whether the conversation is currently connected to the server.
    @MainActor public private(set) var connected: Bool = false

	/// Initializes a new conversation with a given client.
    /// - Parameter client: The `RealtimeAPI` client to use for communication.
	private init(client: RealtimeAPI) {
		self.client = client
		(errors, errorStream) = AsyncStream.makeStream(of: ServerError.self)

		let task = Task.detached { [weak self] in //Handles incoming events from the client
			guard let self else { return }

			for try await event in client.events {
				await self.handleEvent(event)
			}

			await MainActor.run { //Ensures UI updates are performed on the main thread
				self.connected = false
			}
		}

		Task { @MainActor in //Sets up cancellation and disconnection handling
			self.cancelTask = task.cancel

			client.onDisconnect = { [weak self] in
				guard let self else { return }

				Task { @MainActor in
					self.connected = false
				}
			}
		}
	}

	/// Deinitializes the Conversation, finishing the error stream, and canceling the running task.
	deinit {
		errorStream.finish()
		DispatchQueue.main.asyncAndWait {
			cancelTask?()
		}
	}

    /// Initializes a new conversation with a given auth token and model.
    /// - Parameters:
    ///   - token: The authentication token.
    ///   - model: The language model to use (e.g., "gpt-4o-realtime-preview-2024-10-01").  Defaults to "gpt-4o-realtime-preview-2024-10-01".
	public convenience init(authToken token: String, model: String = "gpt-4o-realtime-preview-2024-10-01") {
		self.init(client: RealtimeAPI(authToken: token, model: model))
	}

	/// Initializes a `Conversation` by connecting to a specified URLRequest.
    /// - Parameter request: The URL request for establishing the connection.
	public convenience init(connectingTo request: URLRequest) {
		self.init(client: RealtimeAPI(connectingTo: request))
	}

 	/// Executes a callback when the conversation is connected.
    /// - Parameter callback: The asynchronous callback to execute.
    /// - Returns: The result of the callback.
	@MainActor 
	public func whenConnected<E>(_ callback: @Sendable () async throws(E) -> Void) async throws(E) {
		while true {
			if connected {
				return try await callback()
			}

			try? await Task.sleep(for: .milliseconds(500))
		}
	}

	
    /// Updates the current session with the given changes.
    /// - Parameter callback: A closure that modifies the session in place.
    /// - Throws: `ConversationError.sessionNotFound` if the session is not found.
	public func updateSession(withChanges callback: (inout Session) -> Void) async throws {
		guard var session = await session else {
			throw ConversationError.sessionNotFound
		}
		callback(&session)
		try await updateSession(session)
	}

    /// Updates the session for this conversation.
    /// - Parameter session: The updated session configuration.
    /// - Throws: An error if the session update fails.
	public func updateSession(_ session: Session) async throws {
		var session = session
		session.id = nil  // Update endpoint errors if the session ID is included
		try await client.send(event: .updateSession(session))
	}

	/// Sends an audio delta to the conversation.
    /// - Parameters:
    ///   - audio: The audio data to send.
    ///   - commit: Whether to immediately commit the audio and trigger a response. Defaults to `false`.
    /// - Throws: An error if sending the audio fails.
	public func send(audioDelta audio: Data, commit: Bool = false) async throws {
		try await send(event: .appendInputAudioBuffer(encoding: audio))
		if commit { try await send(event: .commitInputAudioBuffer()) }
	}

	/// Sends a text message to the conversation and optionally requests a response.
	/// - Parameters:
	///   - role: The role of the sender (e.g., .user, .assistant).
	///   - text: The text message to send.
	///   - response: The response configuration (optional). If provided, a response will be requested after sending the message.
	public func send(from role: Item.ItemRole, text: String, response: Response.Config? = nil) async throws {
		try await send(event: .createConversationItem(Item(message: Item.Message(id: String(randomLength: 32), from: role, content: [.input_text(text)]))))
		try await send(event: .createResponse(response))
	}

	/// Sends the result of a function call to the conversation.
    /// - Parameter output: The output of the function call.
    /// - Throws: An error if sending the function call output fails.
	public func send(result output: Item.FunctionCallOutput) async throws {
		try await send(event: .createConversationItem(Item(with: output)))
	}

    /// Sends a client event to the server.
    /// - Parameter event: Event to send
    private func send(event: ClientEvent) async throws {
        try await client.send(event: event)
    }
}

// MARK: - Private Helper Methods

private extension Conversation {
	@MainActor func handleEvent(_ event: ServerEvent) {
		switch event {
			case let .error(event):
				errorStream.yield(event.error)
			case let .sessionCreated(event):
				connected = true
				session = event.session
			case let .sessionUpdated(event):
				session = event.session
			case let .conversationCreated(event):
				id = event.conversation.id
			case let .conversationItemCreated(event):
				entries.append(event.item)
			case let .conversationItemInputAudioTranscriptionCompleted(event):
				updateEvent(id: event.itemId) { message in
					guard case let .input_audio(audio) = message.content[event.contentIndex] else { return }

					message.content[event.contentIndex] = .input_audio(.init(audio: audio.audio, transcript: event.transcript))
				}
			case let .conversationItemInputAudioTranscriptionFailed(event):
				errorStream.yield(event.error)
			case let .conversationItemDeleted(event):
				entries.removeAll { $0.id == event.itemId }
			case let .responseContentPartAdded(event):
				updateEvent(id: event.itemId) { message in
					message.content.insert(.init(from: event.part), at: event.contentIndex)
				}
			case let .responseContentPartDone(event):
				updateEvent(id: event.itemId) { message in
					message.content[event.contentIndex] = .init(from: event.part)
				}
			case let .responseTextDelta(event):
				updateEvent(id: event.itemId) { message in
					guard case let .text(text) = message.content[event.contentIndex] else { return }

					message.content[event.contentIndex] = .text(text + event.delta)
				}
			case let .responseTextDone(event):
				updateEvent(id: event.itemId) { message in
					message.content[event.contentIndex] = .text(event.text)
				}
			case let .responseAudioTranscriptDelta(event):
				updateEvent(id: event.itemId) { message in
					guard case let .audio(audio) = message.content[event.contentIndex] else { return }

					message.content[event.contentIndex] = .audio(.init(audio: audio.audio, transcript: (audio.transcript ?? "") + event.delta))
				}
			case let .responseAudioTranscriptDone(event):
				updateEvent(id: event.itemId) { message in
					guard case let .audio(audio) = message.content[event.contentIndex] else { return }

					message.content[event.contentIndex] = .audio(.init(audio: audio.audio, transcript: event.transcript))
				}
			case let .responseAudioDelta(event):
				updateEvent(id: event.itemId) { message in
					guard case let .audio(audio) = message.content[event.contentIndex] else { return }

					message.content[event.contentIndex] = .audio(.init(audio: audio.audio + event.delta, transcript: audio.transcript))
				}
			case let .responseFunctionCallArgumentsDelta(event):
				updateEvent(id: event.itemId) { functionCall in
					functionCall.arguments.append(event.delta)
				}
			case let .responseFunctionCallArgumentsDone(event):
				updateEvent(id: event.itemId) { functionCall in
					functionCall.arguments = event.arguments
				}
			default:
				return
		}
	}
    /// Updates a message within the conversation entries based on the event handling logic.
    /// - Parameters:
    ///   - id: The ID of the message to update.
    ///   - closure: Modifies the message struct with the incoming data from a server event
	@MainActor
	private func updateEvent(id: String, modifying closure: (inout Item.Message) -> Void) {
		guard let index = entries.firstIndex(where: { $0.id == id }), case var .message(message) = entries[index] else {
			return
		}

		closure(&message)

		entries[index] = .message(message)
	}

    /// Updates a function call within the conversation entries based on the event handling logic.
    /// - Parameters:
    ///   - id: The ID of the function call to update.
    ///   - closure: Modifies the function call data with the data incoming from a server event
	@MainActor
	private func updateEvent(id: String, modifying closure: (inout Item.FunctionCall) -> Void) {
		guard let index = entries.firstIndex(where: { $0.id == id }), case var .functionCall(functionCall) = entries[index] else {
			return
		}

		closure(&functionCall)

		entries[index] = .functionCall(functionCall)
	}
}
