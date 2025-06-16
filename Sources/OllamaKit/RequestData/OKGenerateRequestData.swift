//
//  OKGenerateRequestData.swift
//
//
//  Created by Kevin Hermawan on 10/11/23.
//

import Foundation

/// A structure that encapsulates the data required for generating responses using the Ollama API.
public struct OKGenerateRequestData: Sendable {
    private let stream: Bool
    
    /// A string representing the identifier of the model.
    public let model: String
    
    /// A string containing the initial input or prompt.
    public let prompt: String

    /// An optional string containing the text after the model response.
    public let suffix: String?
    
    /// An optional array of base64-encoded images.
    public let images: [String]?

    /// Optional ``OKJSONValue`` representing the JSON schema for the response.
    /// Be sure to also include "return as JSON" in your prompt
    public let format: OKJSONValue?

    /// Optional boolean for thinking models to enable thinking before responding.
    public let think: Bool?

    /// An optional string specifying the system message.
    public var system: String?
    
    /// An optional array of integers representing contextual information.
    public var context: [Int]?
    
    /// Optional ``OKCompletionOptions`` providing additional configuration for the generation request.
    public var options: OKCompletionOptions?
    
    public init(model: String, prompt: String, suffix: String? = nil, images: [String]? = nil, format: OKJSONValue? = nil, think: Bool? = nil) {
        self.stream = true
        self.model = model
        self.prompt = prompt
        self.suffix = suffix
        self.images = images
        self.format = format
        self.think = think
    }
}

extension OKGenerateRequestData: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(stream, forKey: .stream)
        try container.encode(model, forKey: .model)
        try container.encode(prompt, forKey: .prompt)
        try container.encodeIfPresent(suffix, forKey: .suffix)
        try container.encodeIfPresent(images, forKey: .images)
        try container.encodeIfPresent(format, forKey: .format)
        try container.encodeIfPresent(think, forKey: .think)
        try container.encodeIfPresent(system, forKey: .system)
        try container.encodeIfPresent(context, forKey: .context)
        
        if let options {
            try options.encode(to: encoder)
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case stream, model, prompt, suffix, images, format, think, system, context
    }
}
