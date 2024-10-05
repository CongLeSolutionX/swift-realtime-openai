/// Represents an error that occurred on the server.
/// Conforms to `Codable`, `Equatable`, and `Sendable`.
public struct ServerError: Codable, Equatable, Sendable {
    /// The type of error that occurred (e.g., "invalid_request_error", "server_error").
    public let type: String
    /// A more specific error code, if available.
    public let code: String?
    /// A human-readable message explaining the error.
    public let message: String
    /// The name of the parameter that caused the error, if applicable.
    public let param: String?
    /// The ID of the client event that triggered the error, if available.  This helps correlate errors with specific client actions.
    public let eventId: String?
}