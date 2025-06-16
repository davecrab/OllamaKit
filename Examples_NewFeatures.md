# OllamaKit New Features Examples

This document demonstrates the latest features added to OllamaKit, including thinking model support and enhanced tool use capabilities.

## Thinking Models Support

### Chat API with Thinking

```swift
import OllamaKit

let ollamaKit = OllamaKit()

// Enable thinking for thinking models like DeepSeek-R1
let messages = [
    OKChatRequestData.Message(role: .user, content: "Explain the concept of recursion in programming")
]

let chatData = OKChatRequestData(
    model: "deepseek-r1:latest",
    messages: messages,
    think: true  // Enable thinking mode
)

Task {
    for try await response in ollamaKit.chat(data: chatData) {
        // Access the model's thinking process
        if let thinking = response.message?.thinking {
            print("Model is thinking: \(thinking)")
        }
        
        // Access the regular response
        if let content = response.message?.content {
            print("Response: \(content)")
        }
    }
}
```

### Generate API with Thinking and Suffix

```swift
import OllamaKit

let ollamaKit = OllamaKit()

// Code completion with thinking
var generateData = OKGenerateRequestData(
    model: "deepseek-r1:latest",
    prompt: "def fibonacci(n):",
    suffix: "    return result",  // Text that comes after the completion
    think: true  // Enable thinking mode
)

generateData.options = OKCompletionOptions(temperature: 0.2)

Task {
    for try await response in ollamaKit.generate(data: generateData) {
        // Monitor the model's thinking process
        if let thinking = response.thinking {
            print("Model thinking: \(thinking)")
        }
        
        // Get the generated code
        print("Generated code: \(response.response)")
    }
}
```

## Enhanced Tool Use

### Assistant Messages with Tool Calls

```swift
import OllamaKit

// Create a message with tool calls (for conversation history)
let toolCall = OKChatRequestData.Message.ToolCall(
    function: OKChatRequestData.Message.ToolCall.Function(
        name: "get_weather",
        arguments: .object([
            "location": .string("San Francisco"),
            "format": .string("celsius")
        ])
    ),
    id: "call_123"
)

let assistantMessage = OKChatRequestData.Message(
    role: .assistant,
    content: "",
    toolCalls: [toolCall]
)

// Tool response message
let toolResponseMessage = OKChatRequestData.Message(
    role: .tool,
    content: "Temperature: 18°C, Conditions: Partly cloudy",
    toolCallId: "call_123"
)

let messages = [
    OKChatRequestData.Message(role: .user, content: "What's the weather in San Francisco?"),
    assistantMessage,
    toolResponseMessage,
    OKChatRequestData.Message(role: .user, content: "That's perfect! What about tomorrow?")
]
```

### Complete Tool Use Example with Thinking

```swift
import OllamaKit

let ollamaKit = OllamaKit()

// Define tools
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
    OKChatRequestData.Message(role: .user, content: "What's the weather in Paris? Please think about what information I need.")
]

let chatData = OKChatRequestData(
    model: "deepseek-r1:latest",
    messages: messages,
    tools: [weatherTool],
    think: true  // Enable thinking while using tools
)

Task {
    for try await response in ollamaKit.chat(data: chatData) {
        // Monitor thinking process
        if let thinking = response.message?.thinking {
            print("Model thinking: \(thinking)")
        }
        
        // Handle tool calls
        if let toolCalls = response.message?.toolCalls {
            for toolCall in toolCalls {
                if let function = toolCall.function {
                    print("Tool called: \(function.name ?? "")")
                    
                    if let arguments = function.arguments {
                        switch arguments {
                        case .object(let argDict):
                            print("Arguments: \(argDict)")
                        default:
                            print("Unexpected arguments format")
                        }
                    }
                }
            }
        }
        
        // Handle regular content
        if let content = response.message?.content {
            print("Response: \(content)")
        }
    }
}
```

## Message Types for Different Scenarios

### User Message with Images and Thinking Request

```swift
let userMessage = OKChatRequestData.Message(
    role: .user,
    content: "Analyze this image and explain what you see. Please think step by step.",
    images: ["base64_encoded_image_data"]
)
```

### Assistant Message with Thinking Response

```swift
let assistantMessage = OKChatRequestData.Message(
    role: .assistant,
    content: "Based on my analysis, I can see...",
    thinking: "Let me examine this image carefully. First, I notice..."
)
```

### Tool Response Message

```swift
let toolMessage = OKChatRequestData.Message(
    role: .tool,
    content: "Current temperature: 22°C, Weather: Sunny",
    toolCallId: "call_weather_123"
)
```

## Advanced Features

### Structured Output with Thinking

```swift
let schema: OKJSONValue = .object([
    "type": .string("object"),
    "properties": .object([
        "analysis": .object(["type": .string("string")]),
        "confidence": .object(["type": .string("number")]),
        "reasoning": .object(["type": .string("string")])
    ]),
    "required": .array([.string("analysis"), .string("confidence")])
])

let chatData = OKChatRequestData(
    model: "deepseek-r1:latest",
    messages: [
        OKChatRequestData.Message(role: .user, content: "Analyze the sentiment of this text: 'I love this product!' Return your analysis as JSON.")
    ],
    format: schema,
    think: true
)
```

### Conversation with Multiple Tool Calls

```swift
let conversationMessages = [
    OKChatRequestData.Message(role: .user, content: "I need to plan a trip to Tokyo. Can you help me with weather and flight information?"),
    
    // Assistant decides to call multiple tools
    OKChatRequestData.Message(
        role: .assistant,
        content: "",
        toolCalls: [
            OKChatRequestData.Message.ToolCall(
                function: OKChatRequestData.Message.ToolCall.Function(
                    name: "get_weather",
                    arguments: .object(["location": .string("Tokyo")])
                ),
                id: "call_weather"
            ),
            OKChatRequestData.Message.ToolCall(
                function: OKChatRequestData.Message.ToolCall.Function(
                    name: "search_flights",
                    arguments: .object(["destination": .string("Tokyo")])
                ),
                id: "call_flights"
            )
        ]
    ),
    
    // Tool responses
    OKChatRequestData.Message(role: .tool, content: "Tokyo weather: 15°C, Cloudy", toolCallId: "call_weather"),
    OKChatRequestData.Message(role: .tool, content: "Found 5 flights from $800", toolCallId: "call_flights"),
    
    // User follow-up
    OKChatRequestData.Message(role: .user, content: "Great! What should I pack for that weather?")
]
```

## Error Handling

```swift
Task {
    do {
        for try await response in ollamaKit.chat(data: chatData) {
            // Process response
        }
    } catch {
        print("Error occurred: \(error)")
        // Handle specific error cases
        if let urlError = error as? URLError {
            print("Network error: \(urlError.localizedDescription)")
        }
    }
}
```

## Best Practices

1. **Thinking Models**: Only enable thinking (`think: true`) when using models that support it (like DeepSeek-R1)
2. **Tool Use**: Provide clear tool descriptions and parameter schemas for better tool calling accuracy
3. **Suffix Parameter**: Use suffix for code completion tasks where you want to specify what comes after the generated content
4. **Message History**: Maintain proper conversation flow by including tool calls and responses in message history
5. **Error Handling**: Always wrap API calls in proper error handling to gracefully handle network issues or API errors

## Compatibility

- **Thinking Support**: Requires Ollama with thinking model support (DeepSeek-R1, etc.)
- **Tool Use**: Enhanced tool use features work with all tool-capable models
- **Suffix Parameter**: Works with all models for the generate API
- **Backward Compatibility**: All existing OllamaKit code continues to work unchanged 