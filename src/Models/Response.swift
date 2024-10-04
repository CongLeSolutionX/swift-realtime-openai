public struct Response: Identifiable, Codable, Equatable, Sendable {
	public struct Config: Codable, Equatable, Sendable {
		/// The modalities for the response.
		public let modalities: [Session.Modality]
		/// Instructions for the model.
		public let instructions: String
		/// The voice the model uses to respond.
		public let voice: Session.Voice
		/// The format of output audio.
		public let output_audio_format: Session.AudioFormat
		/// Tools (functions) available to the model.
		public let tools: [Session.Tool]
		/// How the model chooses tools.
		public let tool_choice: Session.ToolChoice
		/// Sampling temperature.
		public let temperature: Double
		/// Maximum number of output tokens.
		public let max_output_tokens: Int?
	}

	public enum Status: String, Codable, Equatable, Sendable {
		case failed
		case completed
		case cancelled
		case incomplete
		case in_progress
	}

	public struct Usage: Codable, Equatable, Sendable {
		public let total_tokens: Int
		public let input_tokens: Int
		public let output_tokens: Int
	}

	/// The unique ID of the response.
	public let id: String
	/// The status of the response.
	public let status: Status
	/// The list of output items generated by the response.
	public let output: [Item]
	/// Usage statistics for the response.
	public let usage: Usage?
}
