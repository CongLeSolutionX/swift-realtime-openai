import Foundation

/// Extends the `String` type with a method to generate a random alphanumeric string.
extension String {
    /// Initializes a new random alphanumeric string of a specified length.
    ///
    /// - Parameter length: The desired length of the random string.
    init(randomLength length: Int) {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789" // Character set for generating the string.
        self = String((0..<length).map { _ in letters.randomElement()! }) // Generates the random string.
    }
}