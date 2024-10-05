import Foundation

/// Extends the `AsyncThrowingStream.Continuation` to provide a convenience method for yielding errors.
extension AsyncThrowingStream.Continuation where Failure == any Error {
    /// Yields a failure to the asynchronous stream. This is a convenience method to simplify error handling.
    /// - Parameter error: The error to yield to the stream.
    func yield(error: Failure) {
        yield(with: .failure(error)) // Yields the error as a failure result to the stream.
    }
}