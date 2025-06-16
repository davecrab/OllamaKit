//
//  ChatWithThinkingView.swift
//  OKPlayground
//
//  Created by AI on 01/01/25.
//

import OllamaKit
import SwiftUI

struct ChatWithThinkingView: View {
    @Environment(ViewModel.self) private var viewModel
    
    @State private var model: String? = nil
    @State private var prompt = ""
    @State private var enableThinking = true
    
    @State private var response = ""
    @State private var thinking = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Model & Settings") {
                    Picker("Model", selection: $model) {
                        ForEach(viewModel.models, id: \.self) { model in
                            Text(model)
                                .tag(model as String?)
                        }
                    }
                    
                    Toggle("Enable Thinking", isOn: $enableThinking)
                        .help("Enables the model to think before responding (requires thinking model)")
                }
                
                Section("Prompt") {
                    TextField("Enter your prompt", text: $prompt, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    Button("Send Message", action: sendMessage)
                        .disabled(isLoading || model == nil || prompt.isEmpty)
                }
                
                if !thinking.isEmpty {
                    Section("Model's Thinking Process") {
                        Text(thinking)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Response") {
                    if isLoading {
                        ProgressView("Generating response...")
                            .frame(maxWidth: .infinity)
                    } else {
                        Text(response.isEmpty ? "No response yet" : response)
                    }
                }
            }
            .navigationTitle("Chat with Thinking")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                model = viewModel.models.first
            }
        }
    }
    
    private func sendMessage() {
        clearResponses()
        isLoading = true
        
        guard let model = model else { return }
        
        let messages = [OKChatRequestData.Message(role: .user, content: prompt)]
        let data = OKChatRequestData(
            model: model,
            messages: messages,
            think: enableThinking ? true : nil
        )
        
        Task {
            do {
                for try await chunk in viewModel.ollamaKit.chat(data: data) {
                    await MainActor.run {
                        if let content = chunk.message?.content {
                            response += content
                        }
                        
                        if let thinkingContent = chunk.message?.thinking {
                            thinking += thinkingContent
                        }
                        
                        if chunk.done {
                            isLoading = false
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    response = "Error: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    private func clearResponses() {
        response = ""
        thinking = ""
    }
}

#Preview {
    ChatWithThinkingView()
        .environment(ViewModel())
} 