import Foundation

/// Represents events sent from the client to the server.
/// Conforms to `Equatable` and `Sendable` for comparisons and concurrency safety.
public enum ClientEvent: Equatable, Sendable {
    
    /// Event to update the session's configuration.
    public struct SessionUpdateEvent: Encodable, Equatable, Sendable {
        /// Optional client-generated ID used to identify this event.
        public var eventId: String?
        /// The session configuration to update.
        public var session: Session
        /// The type identifier for this event.
        private let type = "session.update"
    }

    /// Event to append audio bytes to the input audio buffer.
    public struct InputAudioBufferAppendEvent: Encodable, Equatable, Sendable {
        /// Optional client-generated ID used to identify this event.
        public var eventId: String?
        /// Base64-encoded audio bytes.
        public var audio: String
        /// The type identifier for this event.
        private let type = "input_audio_buffer.append"
    }

    /// Event to commit audio bytes from the buffer to a user message.
    public struct InputAudioBufferCommitEvent: Encodable, Equatable, Sendable {
        /// Optional client-generated ID used to identify this event.
        public var eventId: String?
        /// The type identifier for this event.
        private let type = "input_audio_buffer.commit"
    }

    /// Event to clear the audio bytes in the input audio buffer.
    public struct InputAudioBufferClearEvent: Encodable, Equatable, Sendable {
        /// Optional client-generated ID used to identify this event.
        public var eventId: String?
        /// The type identifier for this event.
        private let type = "input_audio_buffer.clear"
    }

    /// Event to add an item to the conversation.
    public struct ConversationItemCreateEvent: Encodable, Equatable, Sendable {
        /// Optional client-generated ID used to identify this event.
        public var eventId: String?
        /// The ID of the previous item after which the new item will be inserted.
        public var previousItemId: String?
        /// The item to add to the conversation.
        public var item: Item
        /// The type identifier for this event.
        private let type = "conversation.item.create"
    }

    /// Event to truncate a previous assistant message's audio.
    public struct ConversationItemTruncateEvent: Encodable, Equatable, Sendable {
        /// Optional client-generated ID used to identify this event.
        public var eventId: String?
        /// The ID of the assistant message item to truncate.
        public var itemId: String?
        /// The index of the content part to truncate.
        public var contentIndex: Int
        /// Inclusive duration up to which audio is truncated, in milliseconds.
        public var audioEndMs: Int
        /// The type identifier for this event.
        private let type = "conversation.item.truncate"
    }

    /// Event to delete an item from the conversation history.
    public struct ConversationItemDeleteEvent: Encodable, Equatable, Sendable {
        /// Optional client-generated ID used to identify this event.
        public var eventId: String?
        /// The ID of the item to delete.
        public var itemId: String?
        /// The index of the content part to delete.
        public var contentIndex: Int
        /// Inclusive duration up to which audio is deleted, in milliseconds.
        public var audioEndMs: Int
        /// The type identifier for this event.
        private let type = "conversation.item.delete"
    }

    /// Event to trigger a response generation.
    public struct ResponseCreateEvent: Encodable, Equatable, Sendable {
        /// Optional client-generated ID used to identify this event.
        public var eventId: String?
        /// Configuration for the response (optional).
        public var response: Response.Config?
        /// The type identifier for this event.
        private let type = "response.create"
    }

    /// Event to cancel an in-progress response.
    public struct ResponseCancelEvent: Encodable, Equatable, Sendable {
        /// Optional client-generated ID used to identify this event.
        public var eventId: String?
        /// The type identifier for this event.
        private let type = "response.cancel"
    }

    // MARK: - Event Cases

    /// Event to update the session's configuration.
    case updateSession(SessionUpdateEvent)
    /// Event to append audio bytes to the input audio buffer.
    case appendInputAudioBuffer(InputAudioBufferAppendEvent)
    /// Event to commit audio bytes from the buffer to a user message.
    case commitInputAudioBuffer(InputAudioBufferCommitEvent)
    /// Event to clear the audio bytes in the input audio buffer.
    case clearInputAudioBuffer(InputAudioBufferClearEvent)
    /// Event to add an item to the conversation.
    case createConversationItem(ConversationItemCreateEvent)
    /// Event to truncate a previous assistant message's audio.
    case truncateConversationItem(ConversationItemTruncateEvent)
    /// Event to remove an item from the conversation history.
    case deleteConversationItem(ConversationItemDeleteEvent)
    /// Event to initiate a response generation.
    case createResponse(ResponseCreateEvent)
    /// Event to cancel an in-progress response.
    case cancelResponse(ResponseCancelEvent)
}

// MARK: - Convenience Initializers

public extension ClientEvent {
    /// Creates an event to update the session's configuration.
    /// - Parameters:
    ///   - id: Optional event ID.
    ///   - session: The session configuration to update.
    /// - Returns: A `ClientEvent` instance.
    static func updateSession(id: String? = nil, _ session: Session) -> Self {
        .updateSession(SessionUpdateEvent(eventId: id, session: session))
    }

    /// Creates an event to append audio bytes to the input audio buffer.
    /// - Parameters:
    ///   - id: Optional event ID.
    ///   - audio: The audio data to append, base64-encoded.
    /// - Returns: A `ClientEvent` instance.
    static func appendInputAudioBuffer(id: String? = nil, encoding audio: Data) -> Self {
        .appendInputAudioBuffer(InputAudioBufferAppendEvent(eventId: id, audio: audio.base64EncodedString()))
    }

    /// Creates an event to commit audio bytes from the buffer to a user message.
    /// - Parameter id: Optional event ID.
    /// - Returns: A `ClientEvent` instance.
    static func commitInputAudioBuffer(id: String? = nil) -> Self {
        .commitInputAudioBuffer(InputAudioBufferCommitEvent(eventId: id))
    }

    /// Creates an event to clear the audio bytes in the input audio buffer.
    /// - Parameter id: Optional event ID.
    /// - Returns: A `ClientEvent` instance.
    static func clearInputAudioBuffer(id: String? = nil) -> Self {
        .clearInputAudioBuffer(InputAudioBufferClearEvent(eventId: id))
    }

    /// Creates an event to add an item to the conversation.
    /// - Parameters:
    ///   - id: Optional event ID.
    ///   - previousID: The ID of the item after which the new item will be inserted.
    ///   - item: The item to add to the conversation.
    /// - Returns: A `ClientEvent` instance.
    static func createConversationItem(id: String? = nil, previous previousID: String? = nil, _ item: Item) -> Self {
        .createConversationItem(ConversationItemCreateEvent(eventId: id, previousItemId: previousID, item: item))
    }

    /// Creates an event to truncate a previous assistant message's audio.
    /// - Parameters:
    ///   - eventId: Optional event ID.
    ///   - id: The ID of the item to truncate.
    ///   - index: The index of the content part to truncate.
    ///   - audioIndex: The duration up to which audio is truncated, in milliseconds.
    /// - Returns: A `ClientEvent` instance.
    static func truncateConversationItem(id eventId: String? = nil, for id: String? = nil, at index: Int, atAudio audioIndex: Int) -> Self {
        .truncateConversationItem(ConversationItemTruncateEvent(eventId: eventId, itemId: id, contentIndex: index, audioEndMs: audioIndex))
    }

    /// Creates an event to delete an item from the conversation history.
    /// - Parameters:
    ///   - eventId: Optional event ID.
    ///   - id: The ID of the item to delete.
    ///   - index: The index of the content part to delete.
    ///   - audioIndex: The duration up to which audio is deleted, in milliseconds.
    /// - Returns: A `ClientEvent` instance.
    static func deleteConversationItem(id eventId: String? = nil, for id: String? = nil, at index: Int, atAudio audioIndex: Int) -> Self {
        .deleteConversationItem(ConversationItemDeleteEvent(eventId: eventId, itemId: id, contentIndex: index, audioEndMs: audioIndex))
    }

    /// Creates an event to trigger a response generation.
    /// - Parameters:
    ///   - id: Optional event ID.
    ///   - response: Configuration for the response (optional).
    /// - Returns: A `ClientEvent` instance.
    static func createResponse(id: String? = nil, _ response: Response.Config? = nil) -> Self {
        .createResponse(ResponseCreateEvent(eventId: id, response: response))
    }

    /// Creates an event to cancel an in-progress response.
    /// - Parameter id: Optional event ID.
    /// - Returns: A `ClientEvent` instance.
    static func cancelResponse(id: String? = nil) -> Self {
        .cancelResponse(ResponseCancelEvent(eventId: id))
    }
}

// MARK: - Encodable Conformance

extension ClientEvent: Encodable {
    private enum CodingKeys: String, CodingKey {
        case type
    }

    /// Encodes the `ClientEvent` into the given encoder.
    /// - Parameter encoder: The encoder to write data to.
    /// - Throws: An error if any values are invalid for the given encoder’s format.
    public func encode(to encoder: Encoder) throws {
        switch self {
        case let .updateSession(event):
            try event.encode(to: encoder)
        case let .appendInputAudioBuffer(event):
            try event.encode(to: encoder)
        case let .commitInputAudioBuffer(event):
            try event.encode(to: encoder)
        case let .clearInputAudioBuffer(event):
            try event.encode(to: encoder)
        case let .createConversationItem(event):
            try event.encode(to: encoder)
        case let .truncateConversationItem(event):
            try event.encode(to: encoder)
        case let .deleteConversationItem(event):
            try event.encode(to: encoder)
        case let .createResponse(event):
            try event.encode(to: encoder)
        case let .cancelResponse(event):
            try event.encode(to: encoder)
        }
    }
}