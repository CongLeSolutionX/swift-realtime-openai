import XCTest
@testable import OpenAI

// Note: Replace `OpenAI` with the actual name of your Swift package.

final class OpenAITests: XCTestCase {

    // MARK: - Item Tests

    func testItemMessageContentText() throws {
        let content = Item.Message.Content.text("Hello, world!")
        XCTAssertEqual(content.text, "Hello, world!")
    }

    func testItemMessageContentAudio() throws {
        let audioData = Data("test".utf8)
        let audioContent = Item.Message.Content.audio(Item.Audio(audio: audioData, transcript: "Test transcript"))
        XCTAssertEqual(audioContent.text, "Test transcript")


        let audioData2 = Data("test".utf8)
        let audioContent2 = Item.Message.Content.inputAudio(Item.Audio(audio: audioData2, transcript: "Test transcript"))
        XCTAssertEqual(audioContent2.text, "Test transcript")

    }

    func testItemMessageEncodingDecoding() throws {
        let message = Item.Message(id: "123", from: .user, content: [.text("Test message")])
        let encodedData = try JSONEncoder().encode(message)
        let decodedMessage = try JSONDecoder().decode(Item.Message.self, from: encodedData)
        XCTAssertEqual(message, decodedMessage)
    }

    // MARK: - ClientEvent Tests

    func testClientEventUpdateSessionEncoding() throws {
        let session = Session(model: "test-model", instructions: "Test instructions")
        let event = ClientEvent.updateSession(id: "event-id", session)
        let encodedData = try JSONEncoder().encode(event)
        let jsonString = String(data: encodedData, encoding: .utf8)
        XCTAssertNotNil(jsonString) // Simply checks if encoding succeeded without crashing. — More specific assertions could be added based on expected JSON structure.
    }


    func testClientEventAppendInputAudioBuffer() throws {
        let audioData = Data("audio data".utf8)
        let event = ClientEvent.appendInputAudioBuffer(id: "event-id", encoding: audioData)
        let encodedData = try JSONEncoder().encode(event)
        let jsonString = String(data: encodedData, encoding: .utf8)
        XCTAssertNotNil(jsonString) // Add more specific checks and assertions for event properties if needed.



    }
    // ... similar encoding tests for appendInputAudioBuffer, etc. ...

    // MARK: - ServerEvent Tests (Example)


    func testServerEventErrorEventDecoding() throws {
        let jsonData = """
        {"event_id": "error-123", "type": "error", "error": {"type": "invalid_request_error", "message": "Invalid request"}}
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let event = try decoder.decode(ServerEvent.self, from: jsonData)

        if case let ServerEvent.error(errorEvent) = event {
            XCTAssertEqual(errorEvent.eventId, "error-123")
            XCTAssertEqual(errorEvent.error.type, "invalid_request_error")
            XCTAssertEqual(errorEvent.error.message, "Invalid request")


        } else {
            XCTFail("Expected an error event")

        }


    }


    func testConversationItemCreatedEventDecoding() throws {

        let jsonData = """
            {"event_id": "test-event-id",  "type": "conversation.item.created", "previous_item_id": "previous-id", "item": {"id": "item-id",  "type": "message", "role": "user", "content": [{"type": "text", "text": "Hello"}]}}
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let serverEvent = try decoder.decode(ServerEvent.self, from: jsonData)


        if case let .conversationItemCreated(event) = serverEvent {
                XCTAssertEqual(event.eventId, "test-event-id")
                XCTAssertEqual(event.item.id, "item-id")
            } else {
                XCTFail("Decoding failed or incorrect event type")
            }

    }

    // ... decoding tests for SessionEvent, ConversationEvent, etc. ...


    // MARK: - Session Tests


    func testSessionInitialization() {
        let session = Session(model: "gpt-3.5-turbo", instructions: "You are a helpful assistant.")
        XCTAssertEqual(session.model, "gpt-3.5-turbo")
        XCTAssertEqual(session.instructions, "You are a helpful assistant.")
    }

    func testSessionToolChoiceEncoding() throws {
        let toolChoice = Session.ToolChoice.function("my_function")
        let encodedData = try JSONEncoder().encode(toolChoice)
        let jsonString = String(data: encodedData, encoding: .utf8)!
        // Example Assertion:
        XCTAssertTrue(jsonString.contains("my_function"))  // Check if the encoded JSON contains the function name.
    }



    // MARK: - Conversation Tests

    func testConversationInitialization() {
        let expectation = expectation(description: "Conversation connects")
        let conversation = Conversation(authToken: "YOUR_AUTH_TOKEN") // Replace with a valid token or mock for testing.

        Task {
            do {
                try await conversation.whenConnected {
                    //If conversation object is connected to the server, it fullfills this expectation
                    expectation.fulfill()
                }
            } catch {
                XCTFail("Connection failed: \(error)")
            }
        }

        wait(for: [expectation], timeout: 5) //Adjust the timeout if needed




    }



    func testConversationSendTextMessage() async throws {

        let conversation = Conversation(authToken: "YOUR_AUTH_TOKEN") // Replace with a valid token (or mock behavior for proper testing).

        do {
            try await conversation.send(from: .user, text: "Hello")

            //Check conversation object properties to validate message sending
            XCTAssertNotNil(conversation.id)
            //etc.

        } catch {
            XCTFail("Sending message failed: \(error)")
        }
    }



    // MARK: - RealtimeAPI Tests

    func testRealtimeAPIConnection() {
        let expectation = expectation(description: "WebSocket connects")
        let request = URLRequest(url: URL(string: "wss://api.openai.com/v1/realtime?model=gpt-4o-realtime-preview-2024-10-01")!) // Replace with your actual WebSocket URL.
        let api = RealtimeAPI(connectingTo: request)

        api.onDisconnect = {
            // This should not be called during a successful connection test.
            XCTFail("Connection disconnected unexpectedly.")
        }
        Task {
            do {
                for try await _ in api.events {
                    expectation.fulfill() // Expect at least one event (like a session creation event) upon successful connection.
                    break // Exit the loop after receiving the first event.
                    
                }

            } catch {
                XCTFail("Failed to receive event: \(error)")
            }
        }
        wait(for: [expectation], timeout: 5.0)
    }



    // MARK: - Utility Extensions Tests

    func testStringRandomLength() {
        let randomString = String(randomLength: 10)
        XCTAssertEqual(randomString.count, 10)
    }



    func testAsyncThrowingStreamContinuationYieldError() {
        let expectation = expectation(description: "Error yielded")
        var stream: AsyncThrowingStream<Int, Error>? = AsyncThrowingStream { continuation in
            continuation.yield(error: TestError.test)
            continuation.finish()
        }




        Task {
            do {
                for try await _ in stream! {
                    XCTFail("Value yielded unexpectedly.")
                }
            } catch {
                if let error = error as? TestError {
                    XCTAssertEqual(error, .test)
                    expectation.fulfill()
                }


            }
            stream = nil // Release the stream to deinit.
        }


        wait(for: [expectation], timeout: 5)

    }

    //Enum representing a test error
    enum TestError: Error, Equatable {
        case test
    }
}
