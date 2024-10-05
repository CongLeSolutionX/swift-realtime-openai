/// Represents a session, which encapsulates the configuration and state for interactions with the backend.  Conforms to `Codable`, `Equatable`, and `Sendable`.
public struct Session: Codable, Equatable, Sendable {
    /// Represents the supported modalities for communication (e.g., text, audio).
    public enum Modality: String, Codable, Sendable {
        /// Text-based communication.
        case text
        /// Audio-based communication.
        case audio
    }

    /// Represents available voices for audio responses.
    public enum Voice: String, Codable, Sendable {
        /// Alloy voice.
        case alloy
        /// Echo voice.
        case echo
        /// Fable voice.
        case fable
        /// Onyx voice.
        case onyx
        /// Nova voice.
        case nova
        /// Shimmer voice.
        case shimmer
    }

    /// Represents supported audio formats.
    public enum AudioFormat: String, Codable, Sendable {
        /// PCM 16-bit audio.
        case pcm16
        /// G.711 u-law encoded audio.
        case g711Ulaw = "g711_ulaw"
        /// G.711 a-law encoded audio.
        case g711Alaw = "g711_alaw"
    }

    /// Configuration for input audio transcription.
    public struct InputAudioTranscription: Codable, Equatable, Sendable {
        /// The model used for transcription (e.g., "whisper-1").  Defaults to "whisper-1".
        public var model: String
        
        /// Initializes `InputAudioTranscription` with a specified model.
        /// - Parameter model: The transcription model to use.
        public init(model: String = "whisper-1") {
            self.model = model
        }
    }

    /// Configuration for turn detection in audio conversations.
    public struct TurnDetection: Codable, Equatable, Sendable {
        ///  The type of turn detection to use.
        public enum TurnDetectionType: String, Codable, Sendable {
            /// Server-side Voice Activity Detection (VAD).
            case serverVad = "server_vad"
            /// No turn detection.
            case none
        }

        /// The type of turn detection.
        public var type: TurnDetectionType
        /// The activation threshold for VAD (a value between 0.0 and 1.0).
        public var threshold: Double
        /// The amount of audio (in milliseconds) to include before detected speech.
        public var prefixPaddingMs: Int
        /// The duration of silence (in milliseconds) required to trigger the end of a turn.
        public var silenceDurationMs: Int

		/// Initialize TurnDetection
        /// - Parameters:
        ///   - type: The type of turn detection to use.
        ///   - threshold:  The VAD activation threshold.
        ///   - prefixPaddingMs:  Audio prefix padding.
        ///   - silenceDurationMs: Silence duration for turn detection.
		public init(
			type: TurnDetectionType,
			threshold: Double,
			prefixPaddingMs: Int,
			silenceDurationMs: Int
		) {
			self.type = type
			self.threshold = threshold
			self.prefixPaddingMs = prefixPaddingMs
			self.silenceDurationMs = silenceDurationMs
		}
	}

	/// Represents a tool (function) that can be used by the model.
	public struct Tool: Codable, Equatable, Sendable {
		/// Defines the parameters for a function in JSON Schema format.
		public struct FunctionParameters: Codable, Equatable, Sendable {
			//Nested struct to define tool parameters. All properties are optional to handle various tool parameters
			public var type: JSONType
			public var properties: [String: Property]?
			public var required: [String]?
			public var pattern: String?
			public var const: String?
			public var `enum`: [String]?
			public var multipleOf: Int?
			public var minimum: Int?
			public var maximum: Int?

			public init(
				type: JSONType,
				properties: [String: Property]? = nil,
				required: [String]? = nil,
				pattern: String? = nil,
				const: String? = nil,
				enum: [String]? = nil,
				multipleOf: Int? = nil,
				minimum: Int? = nil,
				maximum: Int? = nil
			) {
				self.type = type
				self.properties = properties
				self.required = required
				self.pattern = pattern
				self.const = const
				self.enum = `enum`
				self.multipleOf = multipleOf
				self.minimum = minimum
				self.maximum = maximum
			}

			public struct Property: Codable, Equatable, Sendable {
				// Properties within tool parameters. All properties are optional here as well.
				public var type: JSONType
				public var description: String?
				public var format: String?
				public var items: Items?
				public var required: [String]?
				public var pattern: String?
				public var const: String?
				public var `enum`: [String]?
				public var multipleOf: Int?
				public var minimum: Double?
				public var maximum: Double?
				public var minItems: Int?
				public var maxItems: Int?
				public var uniqueItems: Bool?

				public init(
					type: JSONType,
					description: String? = nil,
					format: String? = nil,
					items: Self.Items? = nil,
					required: [String]? = nil,
					pattern: String? = nil,
					const: String? = nil,
					enum: [String]? = nil,
					multipleOf: Int? = nil,
					minimum: Double? = nil,
					maximum: Double? = nil,
					minItems: Int? = nil,
					maxItems: Int? = nil,
					uniqueItems: Bool? = nil
				) {
					self.type = type
					self.description = description
					self.format = format
					self.items = items
					self.required = required
					self.pattern = pattern
					self.const = const
					self.enum = `enum`
					self.multipleOf = multipleOf
					self.minimum = minimum
					self.maximum = maximum
					self.minItems = minItems
					self.maxItems = maxItems
					self.uniqueItems = uniqueItems
				}

				public struct Items: Codable, Equatable, Sendable {
					//Items struct defines data types like arrays and object properties
					public var type: JSONType
					public var properties: [String: Property]?
					public var pattern: String?
					public var const: String?
					public var `enum`: [String]?
					public var multipleOf: Int?
					public var minimum: Double?
					public var maximum: Double?
					public var minItems: Int?
					public var maxItems: Int?
					public var uniqueItems: Bool?

					public init(
						type: JSONType,
						properties: [String: Property]? = nil,
						pattern: String? = nil,
						const: String? = nil,
						enum: [String]? = nil,
						multipleOf: Int? = nil,
						minimum: Double? = nil,
						maximum: Double? = nil,
						minItems: Int? = nil,
						maxItems: Int? = nil,
						uniqueItems: Bool? = nil
					) {
						self.type = type
						self.properties = properties
						self.pattern = pattern
						self.const = const
						self.enum = `enum`
						self.multipleOf = multipleOf
						self.minimum = minimum
						self.maximum = maximum
						self.minItems = minItems
						self.maxItems = maxItems
						self.uniqueItems = uniqueItems
					}
				}
			}
			
			/// Enum represents JSON data types, including those defined by the JSON Schema.
			public enum JSONType: String, Codable, Sendable {
				case integer
				case string
				case boolean
				case array
				case object
				case number
				case null
			}
		}
        /// The type of the tool (e.g., "function").
        public var type: String
        /// The name of the tool/function.
        public var name: String
        /// A description of the tool/function.
        public var description: String
        /// The parameters the tool/function accepts, defined in JSON Schema format.
        public var parameters: FunctionParameters
	}

    /// Controls how the model chooses to use tools.
    public enum ToolChoice: Equatable, Sendable {
        /// The model automatically decides whether to use tools.
        case auto
        /// The model does not use tools.
        case none
        /// The model is required to use a tool.
        case required
        /// The model uses the specified function.
        case function(String)

        /// Initializes a `.function` ToolChoice with the given function name.
        /// - Parameter name: The name of the function to use.
        public init(function name: String) {
            self = .function(name)
        }
	}

    /// The unique ID of the session (optional).
    public var id: String?
    /// The default language model for the session.
    public var model: String
    /// The allowed modalities for responses (e.g., [.text, .audio]).  Defaults to both text and audio.
    public var modalities: [Modality]
	/// The default system instructions.
	public var instructions: String
	/// The voice the model uses to respond.
	public var voice: Voice
	/// The format of input audio.
	public var inputAudioFormat: AudioFormat
	/// The format of output audio.
	public var outputAudioFormat: AudioFormat
	/// Configuration for input audio transcription.
	public var inputAudioTranscription: InputAudioTranscription?
	/// Configuration for turn detection.
	public var turnDetection: TurnDetection?
	/// Tools (functions) available to the model.
	public var tools: [Tool]
	/// How the model chooses tools.
	public var toolChoice: ToolChoice
	/// Sampling temperature.
	public var temperature: Double
	/// Maximum number of output tokens.
	public var maxOutputTokens: Int?

	/// Initializes a new session with the provided configuration.
    /// - Parameters:
    ///   - id: The unique ID of the session (optional).
    ///   - model: The default language model for the session.
    ///   - tools: Available tools for the session.
    ///   - instructions: Default system instructions for the session.
    ///   - voice: The preferred voice for audio responses. Defaults to `.alloy`.
    ///   - temperature: Sampling temperature for response generation (0.0 - 1.0). Defaults to 1.0.
    ///   - maxOutputTokens: Maximum number of output tokens (optional).
    ///   - toolChoice: How the model chooses tools. Defaults to `.auto`.
    ///   - turnDetection: Configuration for turn detection (optional).
    ///   - inputAudioFormat:  Format for the input audio. Defaults to `.pcm16`.
    ///   - outputAudioFormat: Format for the output audio. Defaults to `.pcm16`
    ///   - modalities:  Allowed response modalities. Defaults to [.text, .audio].
    ///   - inputAudioTranscription: Configuration for audio transcription (optional).
	public init(
		id: String? = nil,
		model: String,
		tools: [Tool] = [],
		instructions: String,
		voice: Voice = .alloy,
		temperature: Double = 1,
		maxOutputTokens: Int? = nil,
		toolChoice: ToolChoice = .auto,
		turnDetection: TurnDetection? = nil,
		inputAudioFormat: AudioFormat = .pcm16,
		outputAudioFormat: AudioFormat = .pcm16,
		modalities: [Modality] = [.text, .audio],
		inputAudioTranscription: InputAudioTranscription? = nil
	) {
		self.id = id
		self.model = model
		self.tools = tools
		self.voice = voice
		self.toolChoice = toolChoice
		self.modalities = modalities
		self.temperature = temperature
		self.instructions = instructions
		self.turnDetection = turnDetection
		self.maxOutputTokens = maxOutputTokens
		self.inputAudioFormat = inputAudioFormat
		self.outputAudioFormat = outputAudioFormat
		self.inputAudioTranscription = inputAudioTranscription
	}
}

// MARK: - Codable extension for Session.ToolChoice

extension Session.ToolChoice: Codable {
	private enum FunctionCall: Codable {
		case type
		case function

		enum CodingKeys: CodingKey {
			case type
			case function
		}
	}

	public init(from decoder: any Decoder) throws {
		let container = try decoder.singleValueContainer()

		if let stringValue = try? container.decode(String.self) {
			switch stringValue {
				case "none":
					self = .none
				case "auto":
					self = .auto
				case "required":
					self = .required
				default:
					throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid value for enum.")
			}
		} else {
			let container = try decoder.container(keyedBy: FunctionCall.CodingKeys.self)
			let functionContainer = try container.decode([String: String].self, forKey: .function)

			guard let name = functionContainer["name"] else {
				throw DecodingError.dataCorruptedError(forKey: .function, in: container, debugDescription: "Missing function name.")
			}

			self = .function(name)
		}
	}

	public func encode(to encoder: Encoder) throws {
		switch self {
			case .none:
				var container = encoder.singleValueContainer()
				try container.encode("none")
			case .auto:
				var container = encoder.singleValueContainer()
				try container.encode("auto")
			case .required:
				var container = encoder.singleValueContainer()
				try container.encode("required")
			case let .function(name):
				var container = encoder.container(keyedBy: FunctionCall.CodingKeys.self)
				try container.encode("function", forKey: .type)
				try container.encode(["name": name], forKey: .function)
		}
	}
}
