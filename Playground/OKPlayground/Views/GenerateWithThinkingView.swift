//
//  GenerateWithThinkingView.swift
//  OKPlayground
//
//  Created by AI on 01/01/25.
//

import OllamaKit
import SwiftUI

struct GenerateWithThinkingView: View {
    @Environment(ViewModel.self) private var viewModel
    
    @State private var model: String? = nil
    @State private var prompt = ""
    @State private var suffix = ""
    @State private var enableThinking = true
    @State private var temperature: Double = 0.5
    
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
                
                Section("Temperature") {
                    Slider(value: $temperature, in: 0...1, step: 0.1) {
                        Text("Temperature: \(temperature, specifier: "%.1f")")
                    } minimumValueLabel: {
                        Text("0")
                    } maximumValueLabel: {
                        Text("1")
                    }
                }
                
                Section("Input") {
                    TextField("Prompt", text: $prompt, axis: .vertical)
                        .lineLimit(3...6)
                    
                    TextField("Suffix (optional)", text: $suffix, axis: .vertical)
                        .lineLimit(2...4)
                        .help("Text that comes after the model response (useful for code completion)")
                }
                
                Section {
                    Button("Generate", action: generate)
                        .disabled(isLoading || model == nil || prompt.isEmpty)
                }
                
                if !thinking.isEmpty {
                    Section("Model's Thinking Process") {
                        Text(thinking)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Generated Response") {
                    if isLoading {
                        ProgressView("Generating response...")
                            .frame(maxWidth: .infinity)
                    } else {
                        Group {
                            if !response.isEmpty {
                                if !suffix.isEmpty {
                                    Text(response + " " + suffix)
                                        .overlay(alignment: .trailing) {
                                            Text(suffix)
                                                .foregroundStyle(.secondary)
                                        }
                                } else {
                                    Text(response)
                                }
                            } else {
                                Text("No response yet")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Generate with Thinking")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                model = viewModel.models.first
            }
        }
    }
    
    private func generate() {
        clearResponses()
        isLoading = true
        
        guard let model = model else { return }
        
        var data = OKGenerateRequestData(
            model: model,
            prompt: prompt,
            suffix: suffix.isEmpty ? nil : suffix,
            think: enableThinking ? true : nil
        )
        data.options = OKCompletionOptions(temperature: temperature)
        
        Task {
            do {
                for try await chunk in viewModel.ollamaKit.generate(data: data) {
                    await MainActor.run {
                        response += chunk.response
                        
                        if let thinkingContent = chunk.thinking {
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
    GenerateWithThinkingView()
        .environment(ViewModel())
} 