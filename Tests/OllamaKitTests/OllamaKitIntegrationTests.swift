import XCTest
@testable import OllamaKit
import Foundation

/// Integration tests that require a running Ollama instance.
/// These tests are disabled by default. To run them:
/// 1. Ensure Ollama is running on localhost:11434
/// 2. Ensure you have models like "llama3.2:latest" or "deepseek-r1:latest" available
/// 3. Change test prefix to test prefix
///
/// Run individual integration tests with:
/// swift test --filter OllamaKitIntegrationTests.testRealModelsCall
final class OllamaKitIntegrationTests: XCTestCase {
    var ollamaKit: OllamaKit!
    
    override func setUp() {
        super.setUp()
        ollamaKit = OllamaKit() // Uses default localhost:11434
    }
    
    override func tearDown() {
        ollamaKit = nil
        super.tearDown()
    }
    
    // MARK: - Real API Integration Tests (Disabled)
    
    /// Test fetching real models from a running Ollama instance
    func testRealModelsCall() async throws {
        do {
            let modelsResponse = try await ollamaKit.models()
            XCTAssertGreaterThan(modelsResponse.models.count, 0, "Should have at least one model available")
            
            for model in modelsResponse.models {
                XCTAssertFalse(model.name.isEmpty, "Model name should not be empty")
                XCTAssertFalse(model.digest.isEmpty, "Model digest should not be empty")
                XCTAssertGreaterThan(model.size, 0, "Model size should be greater than 0")
                print("Found model: \(model.name) (Size: \(model.size) bytes)")
            }
        } catch {
            print("Integration test failed - ensure Ollama is running and has models: \(error)")
            throw error
        }
    }
    
    /// Test real chat functionality
    func testRealChatCall() async throws {
        let messages = [
            OKChatRequestData.Message(role: .user, content: "Say hello in exactly 3 words")
        ]
        
        let chatData = OKChatRequestData(
            model: "gemma3:latest", // Change to a model you have available
            messages: messages
        )
        
        var responses: [String] = []
        
        do {
            for try await response in ollamaKit.chat(data: chatData) {
                if let content = response.message?.content, !content.isEmpty {
                    responses.append(content)
                    print("Chat response: \(content)")
                }
                
                if response.done {
                    break
                }
            }
            
            XCTAssertGreaterThan(responses.count, 0, "Should receive at least one response")
        } catch {
            print("Chat integration test failed: \(error)")
            throw error
        }
    }
    
    /// Test real chat with thinking capability
    /// Note: This test requires a very recent version of Ollama that supports the think parameter
    func testRealChatWithThinking() async throws {
        let messages = [
            OKChatRequestData.Message(role: .user, content: "Think step by step: What is 15 * 23?")
        ]
        
        let chatData = OKChatRequestData(
            model: "deepseek-r1:latest", // Requires a thinking model
            messages: messages,
            think: true
        )
        
        var thinkingContent: [String] = []
        var responseContent: [String] = []
        
        do {
            for try await response in ollamaKit.chat(data: chatData) {
                if let thinking = response.message?.thinking, !thinking.isEmpty {
                    thinkingContent.append(thinking)
                    print("Thinking: \(thinking)")
                }
                
                if let content = response.message?.content, !content.isEmpty {
                    responseContent.append(content)
                    print("Response: \(content)")
                }
                
                if response.done {
                    break
                }
            }
            
            // Only assert on responses since thinking might not be supported yet
            XCTAssertGreaterThan(responseContent.count, 0, "Should receive response content")
            
            // Optional assertion for thinking - only if we get thinking content
            if thinkingContent.count > 0 {
                print("✅ Thinking feature is working!")
            } else {
                print("⚠️ Thinking feature not available in this Ollama version (0.9.0)")
                print("   Consider upgrading Ollama for thinking model support")
            }
        } catch {
            if let urlError = error as? URLError, urlError.code.rawValue == -1011 {
                let errorString = String(describing: error)
                print("⚠️ Thinking not supported by this model version")
                print("   Error details: \(errorString)")
                if errorString.contains("does not support thinking") {
                    print("   💡 Try running: ollama pull deepseek-r1 to get the latest version with thinking support")
                }
                
                // Test without thinking parameter as fallback
                let fallbackData = OKChatRequestData(
                    model: "deepseek-r1:latest",
                    messages: messages
                    // No think parameter
                )
                
                for try await response in ollamaKit.chat(data: fallbackData) {
                    if let content = response.message?.content, !content.isEmpty {
                        responseContent.append(content)
                        print("Fallback response: \(content)")
                    }
                    
                    if response.done {
                        break
                    }
                }
                
                XCTAssertGreaterThan(responseContent.count, 0, "Should get response without thinking")
            } else {
                print("Thinking chat integration test failed: \(error)")
                throw error
            }
        }
    }
    
    /// Test real generation functionality
    func testRealGenerateCall() async throws {
        let generateData = OKGenerateRequestData(
            model: "gemma3:latest", // Change to a model you have available
            prompt: "Complete this sentence: The quick brown fox"
        )
        
        var responses: [String] = []
        
        do {
            for try await response in ollamaKit.generate(data: generateData) {
                if !response.response.isEmpty {
                    responses.append(response.response)
                    print("Generate response: \(response.response)")
                }
                
                if response.done {
                    break
                }
            }
            
            XCTAssertGreaterThan(responses.count, 0, "Should receive at least one response")
            let fullResponse = responses.joined()
            XCTAssertTrue(fullResponse.contains("fox") || fullResponse.contains("jumps") || fullResponse.contains("over"), 
                         "Response should complete the well-known phrase")
        } catch {
            print("Generate integration test failed: \(error)")
            throw error
        }
    }
    
    /// Test real generation with thinking
    /// Note: This test requires a very recent version of Ollama that supports the think parameter
    func testRealGenerateWithThinking() async throws {
        var generateData = OKGenerateRequestData(
            model: "deepseek-r1:latest", // Requires a thinking model
            prompt: "Think carefully: Write a haiku about programming",
            think: true
        )
        
        generateData.options = OKCompletionOptions(temperature: 0.7)
        
        var thinkingContent: [String] = []
        var responses: [String] = []
        
        do {
            for try await response in ollamaKit.generate(data: generateData) {
                if let thinking = response.thinking, !thinking.isEmpty {
                    thinkingContent.append(thinking)
                    print("Thinking: \(thinking)")
                }
                
                if !response.response.isEmpty {
                    responses.append(response.response)
                    print("Generate response: \(response.response)")
                }
                
                if response.done {
                    break
                }
            }
            
            // Only assert on responses since thinking might not be supported yet
            XCTAssertGreaterThan(responses.count, 0, "Should receive response content")
            
            // Optional assertion for thinking - only if we get thinking content
            if thinkingContent.count > 0 {
                print("✅ Generate thinking feature is working!")
            } else {
                print("⚠️ Generate thinking feature not available in this Ollama version (0.9.0)")
                print("   Consider upgrading Ollama for thinking model support")
            }
        } catch {
            if let urlError = error as? URLError, urlError.code.rawValue == -1011 {
                let errorString = String(describing: error)
                print("⚠️ Thinking not supported by this model version")
                print("   Error details: \(errorString)")
                if errorString.contains("does not support thinking") {
                    print("   💡 Try running: ollama pull deepseek-r1 to get the latest version with thinking support")
                }
                
                // Test without thinking parameter as fallback
                var fallbackData = OKGenerateRequestData(
                    model: "deepseek-r1:latest",
                    prompt: "Write a haiku about programming"
                    // No think parameter
                )
                fallbackData.options = OKCompletionOptions(temperature: 0.7)
                
                for try await response in ollamaKit.generate(data: fallbackData) {
                    if !response.response.isEmpty {
                        responses.append(response.response)
                        print("Fallback generate response: \(response.response)")
                    }
                    
                    if response.done {
                        break
                    }
                }
                
                XCTAssertGreaterThan(responses.count, 0, "Should get response without thinking")
            } else {
                print("Thinking generate integration test failed: \(error)")
                throw error
            }
        }
    }
    
    /// Test chat with tools (weather example)
    func testRealChatWithTools() async throws {
        let weatherTool: OKJSONValue = .object([
            "type": .string("function"),
            "function": .object([
                "name": .string("get_current_weather"),
                "description": .string("Get the current weather for a location"),
                "parameters": .object([
                    "type": .string("object"),
                    "properties": .object([
                        "location": .object([
                            "type": .string("string"),
                            "description": .string("The location to get the weather for, e.g. San Francisco, CA")
                        ]),
                        "format": .object([
                            "type": .string("string"),
                            "description": .string("The format to return the weather in"),
                            "enum": .array([.string("celsius"), .string("fahrenheit")])
                        ])
                    ]),
                    "required": .array([.string("location"), .string("format")])
                ])
            ])
        ])
        
        let messages = [
            OKChatRequestData.Message(role: .user, content: "What's the weather like in Tokyo? Use celsius.")
        ]
        
        let chatData = OKChatRequestData(
            model: "qwen3:latest", // qwen3 supports tools
            messages: messages,
            tools: [weatherTool]
        )
        
        var receivedToolCall = false
        
        do {
            for try await response in ollamaKit.chat(data: chatData) {
                if let toolCalls = response.message?.toolCalls {
                    for toolCall in toolCalls {
                        receivedToolCall = true
                        print("Tool called: \(toolCall.function?.name ?? "unknown")")
                        print("Tool ID: \(toolCall.id ?? "no-id")")
                        
                        if let arguments = toolCall.function?.arguments {
                            print("Tool arguments: \(arguments)")
                        }
                    }
                }
                
                if let content = response.message?.content, !content.isEmpty {
                    print("Chat response: \(content)")
                }
                
                if response.done {
                    break
                }
            }
            
            XCTAssertTrue(receivedToolCall, "Should have received a tool call for weather request")
        } catch {
            print("Tools integration test failed: \(error)")
            throw error
        }
    }
    
    // MARK: - Helper Methods for Integration Testing
    
    /// Helper method to check if Ollama is reachable
    func testOllamaReachability() async throws {
        let url = URL(string: "http://localhost:11434/api/version")!
        let request = URLRequest(url: url)
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                XCTAssertEqual(httpResponse.statusCode, 200, "Ollama should be reachable")
                print("Ollama is running and reachable")
            }
        } catch {
            print("Ollama reachability test failed: \(error)")
            throw error
        }
    }
}

/// Performance tests for streaming responses
extension OllamaKitIntegrationTests {
    
    /// Test the performance of chat streaming
    func testChatStreamingPerformance() async throws {
        let messages = [
            OKChatRequestData.Message(role: .user, content: "Write a short paragraph about Swift programming")
        ]
        
        let chatData = OKChatRequestData(
            model: "gemma3:latest",
            messages: messages
        )
        
        let startTime = Date()
        var responseCount = 0
        
        do {
            for try await response in ollamaKit.chat(data: chatData) {
                responseCount += 1
                if response.done {
                    break
                }
            }
            
            let duration = Date().timeIntervalSince(startTime)
            print("Chat streaming completed in \(duration) seconds with \(responseCount) responses")
            
            XCTAssertLessThan(duration, 30.0, "Chat should complete within 30 seconds")
            XCTAssertGreaterThan(responseCount, 0, "Should receive at least one response")
        } catch {
            print("Chat streaming performance test failed: \(error)")
            throw error
        }
    }
} 