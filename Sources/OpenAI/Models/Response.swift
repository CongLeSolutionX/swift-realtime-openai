/// Represents a response generated by the server.
public struct Response: Identifiable, Codable, Equatable, Sendable {
    
    /// Configuration parameters for generating a response.
    public struct Config: Codable, Equatable, Sendable {
        /// The modalities allowed for the response (e.g., text, audio).
        public let modalities: [Session.Modality]
        /// Instructions to guide the model's response generation.
        public let instructions: String
        /// The preferred voice for audio responses.
        public let voice: Session.Voice
        /// The desired audio format for the output.
        public let outputAudioFormat: Session.AudioFormat
        /// Available tools (functions) for the model to use.
        public let tools: [Session.Tool]
        /// The strategy for how the model selects and uses tools.
        public let toolChoice: Session.ToolChoice
        /// The sampling temperature, controlling the randomness of the response (0.0 - deterministic, 1.0 - highly random).
        public let temperature: Double
        /// The maximum number of tokens allowed in the output (optional).
        public let maxOutputTokens: Int?
    }

    /// Represents the status of a response.
    public enum Status: String, Codable, Equatable, Sendable {
        /// The response generation failed.
        case failed
        /// The response generation completed successfully.
        case completed
        /// The response generation was cancelled.
        case cancelled
        /// The response is incomplete.
        case incomplete
        /// The response generation is in progress.
        case inProgress = "in_progress"
    }

    /// Represents usage statistics for a response.
    public struct Usage: Codable, Equatable, Sendable {
        /// The total number of tokens used in the request and response.
        public let totalTokens: Int
        /// The number of tokens used in the input.
        public let inputTokens: Int
        /// The number of tokens used in the output.
        public let outputTokens: Int
    }

    /// The unique identifier for the response.
    public let id: String
    /// The current status of the response.
    public let status: Status
    /// The list of output items generated for the response.
    public let output: [Item]
    /// Usage statistics for the response (optional).
    public let usage: Usage?
}