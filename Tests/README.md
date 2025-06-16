# OllamaKit Tests

This directory contains comprehensive tests for OllamaKit covering all major functionality.

## Test Coverage

### Unit Tests (`OllamaKitTests.swift`)
These tests run automatically and don't require a running Ollama instance:

- **Models API**: Testing model fetching functionality
- **Chat API**: 
  - Basic messaging
  - Multiple message conversations
  - Image support
  - JSON format responses
  - Completion options
- **Tools Support**:
  - Tool definition and calling
  - Assistant messages with tool calls
  - Tool response messages
  - Validation
- **Thinking Models**:
  - Chat with thinking enabled
  - Generate with thinking
  - Combined tools and thinking
- **Generate API**:
  - Basic text generation
  - Code completion with suffix
  - Image input
  - System messages and context
- **Error Handling**: Edge cases and validation

### Integration Tests (`OllamaKitIntegrationTests.swift`)
These tests require a running Ollama instance and are disabled by default (prefixed with `testDisabled`):

- Real API calls to fetch models
- Real chat conversations
- Real chat with thinking models
- Real generation with various options
- Real tool calling functionality
- Performance testing

## Running Tests

### Unit Tests
```bash
# Run all unit tests
swift test

# Run specific test class
swift test --filter OllamaKitTests

# Run specific test method
swift test --filter OllamaKitTests.testChatBasicMessage
```

### Integration Tests (Requires Ollama)
1. **Setup**: Ensure Ollama is running on `localhost:11434`
2. **Models**: Have models like `llama3.2:latest` or `deepseek-r1:latest` available
3. **Enable**: Change `testDisabled` prefix to `test` for the tests you want to run
4. **Run**: Execute with swift test

```bash
# Example: Enable and run model fetching test
# Change testDisabledRealModelsCall to testRealModelsCall in the file, then:
swift test --filter OllamaKitIntegrationTests.testRealModelsCall
```

## Usage Examples

### Basic Chat
```swift
import OllamaKit

let ollamaKit = OllamaKit()

let messages = [
    OKChatRequestData.Message(role: .user, content: "Hello, how are you?")
]

let chatData = OKChatRequestData(
    model: "llama3.2:latest",
    messages: messages
)

// Streaming chat
for try await response in ollamaKit.chat(data: chatData) {
    if let content = response.message?.content {
        print("Response: \(content)")
    }
    
    if response.done {
        break
    }
}
```

### Thinking Models (DeepSeek-R1, Qwen 3)
```swift
import OllamaKit

let ollamaKit = OllamaKit()

let messages = [
    OKChatRequestData.Message(role: .user, content: "Think step by step: What is 15 * 23?")
]

let chatData = OKChatRequestData(
    model: "deepseek-r1:latest", // or "qwen3:latest"
    messages: messages,
    think: true  // Enable thinking mode
)

// Handle both thinking and response content
for try await response in ollamaKit.chat(data: chatData) {
    // Monitor the model's thinking process
    if let thinking = response.message?.thinking {
        print("🧠 Thinking: \(thinking)")
    }
    
    // Get the actual response
    if let content = response.message?.content {
        print("💬 Response: \(content)")
    }
    
    if response.done {
        break
    }
}
```

### Tool Calling (Function Calling)
```swift
import OllamaKit

let ollamaKit = OllamaKit()

// Define a weather tool
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

// Handle tool calls and responses
for try await response in ollamaKit.chat(data: chatData) {
    // Check for tool calls
    if let toolCalls = response.message?.toolCalls {
        for toolCall in toolCalls {
            print("🔧 Tool called: \(toolCall.function?.name ?? "unknown")")
            
            if let arguments = toolCall.function?.arguments {
                print("📋 Arguments: \(arguments)")
                
                // Here you would execute the actual function
                // For example, call your weather API with the arguments
                let result = await callWeatherAPI(arguments)
                
                // Then continue the conversation with the tool result
                // (See "Tool Response" example below)
            }
        }
    }
    
    // Regular chat content
    if let content = response.message?.content {
        print("💬 Response: \(content)")
    }
    
    if response.done {
        break
    }
}
```

### Tool Response (Continuing after tool call)
```swift
// After receiving a tool call and executing it, continue the conversation
let toolResultMessage = OKChatRequestData.Message(
    role: .tool,
    content: "Temperature: 18°C, Conditions: Partly cloudy",
    toolCallId: "call_123" // Use the ID from the tool call if provided
)

// Add the tool result to your messages array
var updatedMessages = originalMessages
updatedMessages.append(assistantMessageWithToolCall) // The assistant's message that included the tool call
updatedMessages.append(toolResultMessage)

let continueData = OKChatRequestData(
    model: "qwen3:latest",
    messages: updatedMessages
)

// Get the final response with tool results
for try await response in ollamaKit.chat(data: continueData) {
    if let content = response.message?.content {
        print("Final response: \(content)")
    }
    
    if response.done {
        break
    }
}
```

### Generate API with Thinking
```swift
import OllamaKit

let ollamaKit = OllamaKit()

var generateData = OKGenerateRequestData(
    model: "deepseek-r1:latest",
    prompt: "Think carefully: Write a haiku about programming",
    think: true
)

generateData.options = OKCompletionOptions(temperature: 0.7)

for try await response in ollamaKit.generate(data: generateData) {
    // Monitor thinking process
    if let thinking = response.thinking {
        print("🧠 Thinking: \(thinking)")
    }
    
    // Get generated content
    if !response.response.isEmpty {
        print("📝 Generated: \(response.response)")
    }
    
    if response.done {
        break
    }
}
```

### Code Completion with Suffix
```swift
var generateData = OKGenerateRequestData(
    model: "qwen2.5-coder:7b",
    prompt: "def fibonacci(n):",
    suffix: "    return result"  // Text that comes after the completion
)

for try await response in ollamaKit.generate(data: generateData) {
    print("Code: \(response.response)")
    
    if response.done {
        break
    }
}
```

### Combining Tools and Thinking
```swift
let chatData = OKChatRequestData(
    model: "qwen3:latest", // Supports both tools and thinking
    messages: messages,
    tools: [weatherTool],
    think: true  // Enable thinking while using tools
)

for try await response in ollamaKit.chat(data: chatData) {
    // See the model think about tool usage
    if let thinking = response.message?.thinking {
        print("🧠 Model thinking: \(thinking)")
    }
    
    // Handle tool calls
    if let toolCalls = response.message?.toolCalls {
        // Process tools...
    }
    
    // Regular content
    if let content = response.message?.content {
        print("💬 Response: \(content)")
    }
    
    if response.done {
        break
    }
}
```

## Test Examples

### Basic Chat Test
```swift
func testChatBasicMessage() async throws {
    let messages = [
        OKChatRequestData.Message(role: .user, content: "Hello, how are you?")
    ]
    
    let chatData = OKChatRequestData(
        model: "llama3.2:latest",
        messages: messages
    )
    
    let stream = ollamaKit.chat(data: chatData)
    XCTAssertNotNil(stream)
}
```

### Thinking Model Test
```swift
func testChatWithThinking() async throws {
    let messages = [
        OKChatRequestData.Message(role: .user, content: "Explain recursion")
    ]
    
    let chatData = OKChatRequestData(
        model: "deepseek-r1:latest",
        messages: messages,
        think: true
    )
    
    XCTAssertTrue(chatData.think == true)
}
```

### Tool Calling Test
```swift
func testChatWithTools() async throws {
    let weatherTool: OKJSONValue = .object([
        "type": .string("function"),
        "function": .object([
            "name": .string("get_current_weather"),
            "description": .string("Get weather for a location"),
            // ... parameters
        ])
    ])
    
    let chatData = OKChatRequestData(
        model: "qwen3:latest", // Use a model that supports tools
        messages: messages,
        tools: [weatherTool]
    )
    
    XCTAssertNotNil(chatData.tools)
}
```

## Test Structure

- **Setup/Teardown**: Proper initialization and cleanup
- **Mocking**: Mock classes for future network layer testing
- **Assertions**: Comprehensive validation of inputs and outputs
- **Documentation**: Clear comments explaining each test case
- **Error Handling**: Tests for edge cases and error conditions

## Model Compatibility

Different Ollama models support different features:

### Tools (Function Calling)
**Supported Models:**
- `qwen3:latest` ✅ (Recommended for tools)
- `llama3.3:latest` ✅
- `llama3.1:latest` ✅ (8B and larger)
- `qwen2.5:latest` ✅

**Not Supported:**
- `gemma3:latest` ❌
- `llama2:latest` ❌
- Older model versions ❌

**Error Handling:**
```swift
// Always handle tool capability errors
for try await response in ollamaKit.chat(data: chatData) {
    // Check for error messages
    if let error = response.error {
        if error.contains("does not support tools") {
            print("⚠️ Model doesn't support tools, falling back to regular chat")
            // Retry without tools
        }
    }
}
```

### Thinking Mode
**Supported Models:**
- `deepseek-r1:latest` ✅ (Recommended for thinking)
- `qwen3:latest` ✅ (With recent updates)
- `deepseek-r1:1.5b` ✅
- `deepseek-r1:7b` ✅

**Requirements:**
- Ollama version 0.9.0 or higher
- Models may need to be re-pulled: `ollama pull deepseek-r1`
- Check model tags for thinking support

**Error Handling:**
```swift
// Handle thinking capability errors
for try await response in ollamaKit.chat(data: chatData) {
    if let error = response.error {
        if error.contains("does not support thinking") {
            print("⚠️ Model doesn't support thinking, using regular mode")
            // Retry without thinking
        }
    }
}
```

### Image Support
**Supported Models:**
- `llava:latest` ✅
- `llama3.2-vision:latest` ✅
- `qwen2-vl:latest` ✅

### Code Completion
**Recommended Models:**
- `qwen2.5-coder:7b` ✅
- `deepseek-coder:latest` ✅
- `codellama:latest` ✅

### Basic Chat
**Supported by all models** ✅

## Implementation Best Practices

### 1. Always Use Streaming
```swift
// ✅ GOOD: Always use streaming for real-time responses
for try await response in ollamaKit.chat(data: chatData) {
    // Handle streaming responses
}

// ❌ BAD: Don't wait for complete response
let response = try await ollamaKit.chat(data: chatData).first()
```

### 2. Handle Tool Calls Properly
```swift
// Tool call workflow:
// 1. Send message with tools
// 2. Model responds with tool_calls
// 3. Execute the actual function
// 4. Send tool result back to model
// 5. Model provides final response

var conversationHistory: [OKChatRequestData.Message] = []

// Step 1 & 2: Initial request and tool call
for try await response in ollamaKit.chat(data: chatData) {
    if let message = response.message {
        conversationHistory.append(message)
        
        if let toolCalls = message.toolCalls {
            // Step 3: Execute tools
            for toolCall in toolCalls {
                let result = executeFunction(toolCall)
                
                // Step 4: Add tool result to conversation
                let toolMessage = OKChatRequestData.Message(
                    role: .tool,
                    content: result,
                    toolCallId: toolCall.id
                )
                conversationHistory.append(toolMessage)
            }
            
            // Step 5: Continue conversation with tool results
            let continueChat = OKChatRequestData(
                model: "qwen3:latest",
                messages: conversationHistory
            )
            
            // Get final response...
        }
    }
}
```

### 3. Thinking Mode Best Practices
```swift
// Separate thinking from response content
for try await response in ollamaKit.chat(data: chatData) {
    // Show thinking process to user (optional)
    if let thinking = response.message?.thinking {
        updateThinkingUI(thinking)
    }
    
    // Show actual response
    if let content = response.message?.content {
        updateResponseUI(content)
    }
}
```

### 4. Error Recovery Strategies
```swift
func chatWithFallback(messages: [OKChatRequestData.Message], preferredModel: String) async {
    var chatData = OKChatRequestData(model: preferredModel, messages: messages, think: true, tools: tools)
    
    do {
        for try await response in ollamaKit.chat(data: chatData) {
            if let error = response.error {
                if error.contains("does not support thinking") {
                    // Retry without thinking
                    chatData.think = false
                    continue
                } else if error.contains("does not support tools") {
                    // Retry without tools
                    chatData.tools = nil
                    continue
                }
            }
            
            // Handle successful response...
        }
    } catch {
        print("Chat failed: \(error)")
        // Fallback to basic model
        let fallbackData = OKChatRequestData(model: "llama3.2:latest", messages: messages)
        // ... retry with fallback
    }
}
```

## Important Notes

### Model Requirements
- **Thinking Models**: Requires Ollama 0.9.0+ and updated models
  ```bash
  ollama pull deepseek-r1  # Get latest version with thinking support
  ollama pull qwen3        # Get latest version with thinking support
  ```
- **Tool Calling**: Use `qwen3:latest` or `llama3.1:latest` (8B+) for best results
- **Streaming**: All features work with streaming enabled (this was previously a bug)

## Future Enhancements

- Network layer mocking for more isolated unit tests
- Response validation against real API schemas
- Load testing for streaming responses
- Error simulation and recovery testing
- Custom base URL testing 