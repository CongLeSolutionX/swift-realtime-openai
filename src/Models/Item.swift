/// Represents a generic item in a conversation.
/// Conforming to `Identifiable`, `Equatable`, and `Sendable` for ease of use in SwiftUI and concurrency.
public enum Item: Identifiable, Equatable, Sendable {
    /// Represents the status of an item.
    public enum ItemStatus: String, Codable, Sendable {
        /// The item has been completed.
        case completed
        /// The item is currently in progress.
        case inProgress = "in_progress"
        /// The item is incomplete.
        case incomplete
    }

    /// Represents the role associated with an item.
    public enum ItemRole: String, Codable, Sendable {
        /// The item is associated with the user.
        case user
        /// The item is associated with the system.
        case system
        /// The item is associated with the assistant.
        case assistant
    }

    /// Represents an audio message. Conforming to `Equatable` and `Sendable`.
    public struct Audio: Equatable, Sendable {
        /// Base64-encoded audio data.
        public var audio: Data
        /// The transcript of the audio (optional).
        public var transcript: String?

        /// Initializes an `Audio` instance.
        /// - Parameters:
        ///   - audio: The audio data.
        ///   - transcript: The audio transcript (optional).
        public init(audio: Data = Data(), transcript: String? = nil) {
            self.audio = audio
            self.transcript = transcript
        }
    }

    /// Represents a part of the content in an item. Conforming to `Equatable` and `Sendable`.
    public enum ContentPart: Equatable, Sendable {
        /// Text content.
        case text(String)
        /// Audio content.
        case audio(Audio)
    }

    /// Represents a message item within a conversation. Conforming to `Codable`, `Equatable`, and `Sendable`.
    public struct Message: Codable, Equatable, Sendable {
        /// Represents the type of content within a message. 
        /// Conforming to `Equatable` and `Sendable`.
        public enum Content: Equatable, Sendable {
            /// Textual content.
            case text(String)
            /// Audio content.
            case audio(Audio)
            /// User input in text format.
            case inputText(String)
            /// User input in audio format.
            case inputAudio(Audio)

            /// Returns the text representation of the content, if available.
            public var text: String? {
                switch self {
                case let .text(text), let .inputText(text):
                    return text
                case let .inputAudio(audio), let .audio(audio):
                    return audio.transcript
                }
            }
        }

        /// The unique identifier of the message.
        public var id: String
        /// The type of the item (always "message").
        private var type: String = "message"
        /// The status of the message.
        public var status: ItemStatus
        /// The role associated with the message.
        public var role: ItemRole
        /// The content of the message.
        public var content: [Content]

        /// Initializes a `Message` instance.
        /// - Parameters:
        ///   - id: The unique ID of the message.
        ///   - role: The role associated with the message.
        ///   - content: The content of the message.
        public init(id: String, from role: ItemRole, content: [Content]) {
            self.id = id
            self.role = role
            self.status = .completed
            self.content = content
        }
    }

    /// Represents a function call item within a conversation.
    /// Conforming to `Codable`, `Equatable`, and `Sendable`.
    public struct FunctionCall: Codable, Equatable, Sendable {
        /// The unique identifier of the function call.
        public var id: String
        /// The type of the item (always "function_call").
        private var type: String = "function_call"
        /// The status of the function call.
        public var status: ItemStatus
        /// The role associated with the function call.
        public var role: ItemRole
        /// The ID of the function being called.
        public var callId: String
        /// The name of the function being called.
        public var name: String
        /// The arguments of the function call.
        public var arguments: String
    }

    /// Represents the output of a function call.
    /// Conforming to `Codable`, `Equatable`, and `Sendable`.
    public struct FunctionCallOutput: Codable, Equatable, Sendable {
        /// The unique identifier of the function call output.
        public var id: String
        /// The type of the item (always "function_call_output").
        private var type: String = "function_call_output"
        /// The status of the function call output.
        public var status: ItemStatus
        /// The role associated with the function call output.
        public var role: ItemRole
        /// The ID of the function call.
        public var callId: String
        /// The output of the function call.
        public var output: String
    }

    /// A message item.
    case message(Message)
    /// A function call item.
    case functionCall(FunctionCall)
    /// A function call output item.
    case functionCallOutput(FunctionCallOutput)

    /// Returns the unique identifier of the item.
    public var id: String {
        switch self {
        case let .message(message):
            return message.id
        case let .functionCall(functionCall):
            return functionCall.id
        case let .functionCallOutput(functionCallOutput):
            return functionCallOutput.id
        }
    }

    /// Initializes an `Item` instance with a message.
    /// - Parameter message: The message data.
    public init(message: Message) {
        self = .message(message)
    }

    /// Initializes an `Item` instance with a function call.
    /// - Parameter functionCall: The function call data.
    public init(calling functionCall: FunctionCall) {
        self = .functionCall(functionCall)
    }

    /// Initializes an `Item` instance with a function call output.
    /// - Parameter functionCallOutput: The function call output data.
    public init(with functionCallOutput: FunctionCallOutput) {
        self = .functionCallOutput(functionCallOutput)
    }
}

// MARK: - Helpers

public extension Item.Message.Content {
    /// Initializes a `Content` instance from a `ContentPart`.
    /// - Parameter part: The content part to initialize from.
    init(from part: Item.ContentPart) {
        switch part {
        case let .audio(audio):
            self = .audio(audio)
        case let .text(text):
            self = .text(text)
        }
    }
}

// MARK: - Codable Implementations

extension Item: Codable {
    private enum CodingKeys: String, CodingKey {
        case type
    }

    /// Decodes an `Item` instance from a decoder.
    /// - Parameter decoder: The decoder to use for decoding.
    /// - Throws: A `DecodingError` if decoding fails.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "message":
            self = try .message(Message(from: decoder))
        case "function_call":
            self = try .functionCall(FunctionCall(from: decoder))
        case "function_call_output":
            self = try .functionCallOutput(FunctionCallOutput(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown item type: \(type)")
        }
    }

    /// Encodes an `Item` instance to an encoder.
    /// - Parameter encoder: The encoder to use for encoding.
    /// - Throws: An `EncodingError` if encoding fails.
    public func encode(to encoder: Encoder) throws {
        switch self {
        case let .message(message):
            try message.encode(to: encoder)
        case let .functionCall(functionCall):
            try functionCall.encode(to: encoder)
        case let .functionCallOutput(functionCallOutput):
            try functionCallOutput.encode(to: encoder)
        }
    }
}

extension Item.Audio: Decodable {
    private enum CodingKeys: String, CodingKey {
        case audio
        case transcript
    }

    /// Decodes an `Audio` instance from a decoder.
    /// - Parameter decoder: The decoder to use for decoding.
    /// - Throws: A `DecodingError` if decoding fails.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        transcript = try container.decodeIfPresent(String.self, forKey: .transcript)
        let encodedAudio = try container.decodeIfPresent(String.self, forKey: .audio)

        if let encodedAudio {
            guard let decodedAudio = Data(base64Encoded: encodedAudio) else {
                throw DecodingError.dataCorruptedError(forKey: .audio, in: container, debugDescription: "Invalid base64-encoded audio data.")
            }
            audio = decodedAudio
        } else {
            audio = Data()
        }
    }
}

extension Item.ContentPart: Decodable {
    private enum CodingKeys: String, CodingKey {
        case type
        case text
        case audio
        case transcript
    }

    private struct Text: Codable {
        let text: String

        enum CodingKeys: CodingKey {
            case text
        }
    }

    /// Decodes a `ContentPart` instance from a decoder.
    /// - Parameter decoder: The decoder to use for decoding.
    /// - Throws: A `DecodingError` if decoding fails.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "text":
            let container = try decoder.container(keyedBy: Text.CodingKeys.self)
            self = try .text(container.decode(String.self, forKey: .text))
        case "audio":
            self = try .audio(Item.Audio(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown content type: \(type)")
        }
    }
}

extension Item.Message.Content: Codable {
    private enum CodingKeys: String, CodingKey {
        case type
        case text
        case audio
        case transcript
    }

    private struct Text: Codable {
        let text: String

        enum CodingKeys: CodingKey {
            case text
        }
    }

    /// Decodes a `Content` instance from a decoder.
    /// - Parameter decoder: The decoder to use for decoding.
    /// - Throws: A `DecodingError` if decoding fails.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "text":
            let container = try decoder.container(keyedBy: Text.CodingKeys.self)
            self = try .text(container.decode(String.self, forKey: .text))
        case "input_text":
            let container = try decoder.container(keyedBy: Text.CodingKeys.self)
            self = try .inputText(container.decode(String.self, forKey: .text))
        case "audio":
            self = try .audio(Item.Audio(from: decoder))
        case "input_audio":
            self = try .inputAudio(Item.Audio(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown content type: \(type)")
        }
    }

    /// Encodes a `Content` instance with the given encoder.
    /// - Parameter encoder: The encoder to use for encoding.
    /// - Throws: An `EncodingError` if encoding fails.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case let .text(text):
            try container.encode(text, forKey: .text)
            try container.encode("text", forKey: .type)
        case let .inputText(text):
            try container.encode(text, forKey: .text)
            try container.encode("input_text", forKey: .type)
        case let .audio(audio):
            try container.encode("audio", forKey: .type)
            try container.encode(audio.transcript, forKey: .transcript)
            try container.encode(audio.audio.base64EncodedString(), forKey: .audio)
        case let .inputAudio(audio):
            try container.encode("input_audio", forKey: .type)
            try container.encode(audio.transcript, forKey: .transcript)
            try container.encode(audio.audio.base64EncodedString(), forKey: .audio)
        }
    }
}