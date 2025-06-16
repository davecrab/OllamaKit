//
//  OKChatRequestData.swift
//
//
//  Created by Augustinas Malinauskas on 12/12/2023.
//

import Foundation

/// A structure that encapsulates data for chat requests to the Ollama API.
public struct OKChatRequestData: Sendable {
    private let stream: Bool
    
    /// A string representing the model identifier to be used for the chat session.
    public let model: String
    
    /// An array of ``Message`` instances representing the content to be sent to the Ollama API.
    public let messages: [Message]
    
    /// An optional array of ``OKJSONValue`` representing the tools available for tool calling in the chat.
    public let tools: [OKJSONValue]?

    /// Optional ``OKJSONValue`` representing the JSON schema for the response.
    /// Be sure to also include "return as JSON" in your prompt
    public let format: OKJSONValue?

    /// Optional boolean for thinking models to enable thinking before responding.
    public let think: Bool?

    /// Optional ``OKCompletionOptions`` providing additional configuration for the chat request.
    public var options: OKCompletionOptions?
    
    public init(model: String, messages: [Message], tools: [OKJSONValue]? = nil, format: OKJSONValue? = nil, think: Bool? = nil) {
        self.stream = true
        self.model = model
        self.messages = messages
        self.tools = tools
        self.format = format
        self.think = think
    }
    
    /// A structure that represents a single message in the chat request.
    public struct Message: Encodable, Sendable {
        /// A ``Role`` value indicating the sender of the message (system, assistant, user).
        public let role: Role
        
        /// A string containing the message's content.
        public let content: String
        
        /// An optional array of base64-encoded images.
        public let images: [String]?

        /// An optional identifier for the tool call, required if the role is `.tool`.
        public let toolCallId: String?

        /// An optional array of ``ToolCall`` instances representing tool calls made by the assistant.
        public let toolCalls: [ToolCall]?

        /// An optional string containing the model's thinking process (for thinking models).
        public let thinking: String?
        
        public init(role: Role, content: String, images: [String]? = nil, toolCallId: String? = nil, toolCalls: [ToolCall]? = nil, thinking: String? = nil) {
            // Ensure toolCallId is provided if role is tool, and not provided otherwise
            if role == .tool {
                precondition(toolCallId != nil, "toolCallId must be provided when role is .tool")
            } else {
                precondition(toolCallId == nil, "toolCallId must be nil when role is not .tool")
            }
            
            self.role = role
            self.content = content
            self.images = images
            self.toolCallId = toolCallId
            self.toolCalls = toolCalls
            self.thinking = thinking
        }
        
        /// An enumeration that represents the role of the message sender.
        public enum Role: String, Encodable, Sendable {
            /// Indicates the message is from the system.
            case system
            
            /// Indicates the message is from the assistant.
            case assistant
            
            /// Indicates the message is from the user.
            case user

            /// Indicates the message is from a tool response
            case tool
        }

        /// A structure that represents a tool call in the request.
        public struct ToolCall: Encodable, Sendable {
            /// An optional ``Function`` structure representing the details of the tool call.
            public let function: Function?
            
            /// The unique identifier for this specific tool call.
            public let id: String?
            
            /// A structure that represents the details of a tool call.
            public struct Function: Encodable, Sendable {
                /// The name of the tool being called.
                public let name: String?
                
                /// An optional ``OKJSONValue`` representing the arguments passed to the tool.
                public let arguments: OKJSONValue?
            }
        }

        // Custom encoding to include conditional fields
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(role, forKey: .role)
            try container.encode(content, forKey: .content)
            try container.encodeIfPresent(images, forKey: .images)
            try container.encodeIfPresent(thinking, forKey: .thinking)
            try container.encodeIfPresent(toolCalls, forKey: .toolCalls)
            
            if role == .tool {
                try container.encode(toolCallId, forKey: .toolCallId)
            }
        }
        
        private enum CodingKeys: String, CodingKey {
            case role, content, images, thinking
            case toolCallId = "tool_call_id" // Map to JSON key
            case toolCalls = "tool_calls"
        }
    }
}

extension OKChatRequestData: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(stream, forKey: .stream)
        try container.encode(model, forKey: .model)
        try container.encode(messages, forKey: .messages)
        try container.encodeIfPresent(tools, forKey: .tools)
        try container.encodeIfPresent(format, forKey: .format)
        try container.encodeIfPresent(think, forKey: .think)

        if let options {
            try options.encode(to: encoder)
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case stream, model, messages, tools, format, think
    }
}
